#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <time.h>
#include "config.h"
#include "wifi_setup.h"
#include "firebase_setup.h"
#include "ntp_client.h"
#include "led_effects.h"
#include "temperature_sensor.h"

void blinkLED(int pin, int times, int delayTime);  // Declare blinkLED function
void autoRunSystem();  // Declare autoRunSystem function

void setup() {
    Serial.println("Starting...");
    Serial.begin(115200);
    pixels.begin();
    pixels.setBrightness(brightness);

    pinMode(LedBeLow, OUTPUT);
    digitalWrite(LedBeLow, HIGH);
    pinMode(ena, OUTPUT);
    pinMode(bomKKLow, OUTPUT);
    pinMode(lamp, OUTPUT);
    digitalWrite(lamp, HIGH);
    pinMode(levelLampHigh, OUTPUT);
    digitalWrite(levelLampHigh, HIGH);

    if (initWifi()) {
        Serial.println("WiFi connected");

        delay(1000);
        initTimeClient();
        Serial.println("Time client connected");

        delay(500);
        initFirebase();
        Serial.println("Firebase connected");

        _syncDataFromFirebase(&fbdo);  // Truyền tham số fbdo
        Serial.println("Sync data from Firebase");

        sensors.begin();
        Serial.println("Temperature sensor started");

        updateTemperature(&fbdo, lastTemperature);  // Truyền tham số fbdo
        Serial.println("Initial temperature data pushed");
    } else {
        Serial.println("Cannot proceed without WiFi connection.");
        initWifi();
    }
    Serial.println("setup done");
}

void loop() {
    // Kiểm tra kết nối WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected. Reconnecting...");
        if (wifiState == true) {
            blinkLED(LedBeLow, 4, 500);  // Nhấp nháy 3 lần khi mất kết nối
            wifiState = false;
        }
        initWifi();
        if (WiFi.status() == WL_CONNECTED) {
            blinkLED(LedBeLow, 2, 400);  // Nhấp nháy 2 lần khi kết nối lại
        }
    }
    // Kiểm tra kết nối Firebase
    if (Firebase.ready()) {
        checkFirebaseStream(&fbdo_status);
        checkFirebaseStream(&fbdo_led);
        checkFirebaseStream(&fbdo_lamp);
        checkFirebaseStream(&fbdo_aquarium);
    }
    delay(100);
    // autoSyncTime();
    // khi hệ thống tự động, chay autoRunSystem
    if (autoSystem) {
        autoRunSystem();
    }
    getTemperatures();
    // Execute LED effects based on currentEffect
    executeLEDEffects();
}

void blinkLED(int pin, int times, int delayTime) {
    for (int i = 0; i < times; i++) {
        digitalWrite(pin, HIGH);
        delay(delayTime);
        digitalWrite(pin, LOW);
        delay(delayTime);
    }
}

void autoRunSystem() {
    if (timeClient.isTimeSet()) {
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);

        int currentHour = timeClient.getHours();
        int currentMinute = timeClient.getMinutes();
        int currentSecond = timeClient.getSeconds();

        Serial.println("🕒 Time: " + String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                       String(currentMinute));
        // Cập nhật thời gian lên Firebase vào lúc khởi động
        if (!initTimeUpFirebase) {
            timeClient.forceUpdate();
            currentHour = timeClient.getHours();
            currentMinute = timeClient.getMinutes();
            currentSecond = timeClient.getSeconds();

            //cập nhật cả giây
            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute) + ":" + String(currentSecond);
            Firebase.RTDB.setString(&fbdo, "/status/time", currentTime);
            initTimeUpFirebase = true;
        }

        if (currentMinute == 0 || currentMinute == 20 || currentMinute == 40) {
            timeClient.forceUpdate();
            currentHour = timeClient.getHours();
            currentMinute = timeClient.getMinutes();
            currentSecond = timeClient.getSeconds();

            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute) + ":" + String(currentSecond);
            Firebase.RTDB.setString(&fbdo, "/status/time", currentTime);
            delay(60000);
        }

        if (currentHour >= 9 && currentHour <= 23) {
            if (!is_led) {
                digitalWrite(LedBeLow, LOW);
                Firebase.RTDB.setBool(&fbdo, "/status/bigLight", true);
                Firebase.RTDB.setBool(&fbdo, "/aquarium/bigLight", true);
                is_led = true;
            }
        } else {
            if (is_led) {
                digitalWrite(LedBeLow, HIGH);
                Firebase.RTDB.setBool(&fbdo, "/status/bigLight", false);
                Firebase.RTDB.setBool(&fbdo, "/aquarium/bigLight", false);
                is_led = false;
            }
        }
        // Tự động bật bơm nước waterPump theo lịch trình hàng ngày
        //  '4:30 - 9:00, 10:00 - 13:00, 14:00 - 17:00, 18:00 - 21:00, 22:00 - 00:59',
        int currentTime =
                currentHour * 60 + currentMinute;  // Chuyển thời gian thành phút để so sánh dễ dàng

        bool shouldTurnOn = (currentTime >= 270 && currentTime < 540) ||    // 4:30 - 9:00
                            (currentTime >= 600 && currentTime < 780) ||    // 10:00 - 13:00
                            (currentTime >= 840 && currentTime < 1020) ||   // 14:00 - 17:00
                            (currentTime >= 1080 && currentTime < 1260) ||  // 18:00 - 21:00
                            (currentTime >= 1320 || currentTime < 59);      // 22:00 - 00:59

        if (shouldTurnOn) {
            if (is_bom == false) {
                digitalWrite(bomKKLow, LOW);
                Firebase.RTDB.setBool(&fbdo, "/status/waterPump", true);
                Firebase.RTDB.setBool(&fbdo, "/aquarium/waterPump", true);
                is_bom = true;
            }
        } else {
            if (is_bom == true) {
                digitalWrite(bomKKLow, HIGH);
                Firebase.RTDB.setBool(&fbdo, "/status/waterPump", false);
                Firebase.RTDB.setBool(&fbdo, "/aquarium/waterPump", false);
                is_bom = false;
            }
        }
    } else {
        Serial.println("Waiting for NTP time sync...");
        timeClient.forceUpdate();
    }
}

void handleFirebaseStream(FirebaseData *fbdo) {
    String path = fbdo->dataPath();
    Serial.print("Stream path: ");
    Serial.println(path);
    // /status/auto
    if (path == "/auto") {
        autoSystem = fbdo->boolData();
        updateLamp();
    }
        // /lamp/status
    else if (path == "/status") {
        lampState = fbdo->boolData();
        updateLamp();
    }
        // /aquarium/bigLight
    else if (path == "/bigLight") {
        is_led = fbdo->boolData();
        if (is_led == true && autoSystem == false) {
            digitalWrite(LedBeLow, LOW);
        } else if (is_led == false && autoSystem == false) {
            digitalWrite(LedBeLow, HIGH);
        }
    }
        // /led/currentEffect
    else if (path == "/currentEffect") {
        currentEffect = fbdo->intData();
    }
        // /lamp/level
    else if (path == "/level") {
        levelLampHighState = fbdo->boolData();
        updateLamp();
    }
        // aquarium/waterPump
    else if (path == "/waterPump") {
        is_bom = fbdo->boolData();
        Serial.print("is_bom: ");
        Serial.println(is_bom);
        if (is_bom == true && autoSystem == false) {
            digitalWrite(bomKKLow, LOW);
        } else if (is_bom == false && autoSystem == false) {
            digitalWrite(bomKKLow, HIGH);
        }
    }
        // /led/brightness
    else if (path == "/brightness") {
        brightness = fbdo->intData();
        pixels.setBrightness(brightness);
    }
        // /aquarium/airPumpSpeed
    else if (path == "/airPumpSpeed") {
        airPumpSpeed = fbdo->intData();
        analogWrite(ena, map(airPumpSpeed, 0, 9, 0, 255));
    }
        // /led/speed
    else if (path == "/speed") {
        speed = fbdo->intData();
    }
        // /led/color
    else if (path == "/color") {
        FirebaseJson json = fbdo->jsonObject();
        FirebaseJsonData jsonData;
        int r = 0, g = 0, b = 0;

        json.get(jsonData, "r");
        if (jsonData.success) {
            r = jsonData.to<int>();
        }

        json.get(jsonData, "g");
        if (jsonData.success) {
            g = jsonData.to<int>();
        }

        json.get(jsonData, "b");
        if (jsonData.success) {
            b = jsonData.to<int>();
        }

        selectedColor = pixels.Color(r, g, b);
    }
}

// Cập nhật trạng thái đèn bàn học
void updateLamp() {
    if (lampState == true) {
        digitalWrite(lamp, LOW);  // Tắt đèn
    } else {
        digitalWrite(lamp, HIGH);  // Bật đèn
    }

    if (levelLampHighState == true) {
        digitalWrite(levelLampHigh, LOW);  // Tắt đèn
    } else {
        digitalWrite(levelLampHigh, HIGH);  // Bật đèn
    }
}