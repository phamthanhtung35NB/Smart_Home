#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <time.h>
#include "config.h"
#include "esp_wifi.h"
#include "wifi_setup.h"
#include "firebase_setup.h"
#include "ntp_client.h"
#include "led_effects.h"
#include "temperature_sensor.h"
#include "dht11_sensor.h"

void blinkLED(int pin, int times, int delayTime);  // Declare blinkLED function
void autoRunSystem();                              // Declare autoRunSystem function

void setup() {
    Serial.println("Starting...");
    Serial.begin(115200);
    // pixels.begin();
    // pixels.setBrightness(brightness);

    pinMode(LedBeLow, OUTPUT);
    digitalWrite(LedBeLow, HIGH);

    // pinMode(ena, OUTPUT);

    pinMode(bomKKLow, OUTPUT);
    digitalWrite(bomKKLow, HIGH);

    pinMode(FAN_PIN, OUTPUT);
    digitalWrite(FAN_PIN, HIGH);
    pinMode(HEATER_PIN, OUTPUT);
    digitalWrite(HEATER_PIN, HIGH);
    //    pinMode(lamp, OUTPUT);
    //    digitalWrite(lamp, HIGH);
    //    pinMode(levelLampHigh, OUTPUT);
    //    digitalWrite(levelLampHigh, HIGH);
    dht.begin();
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
// Disable all wakeup sources
    esp_sleep_disable_wakeup_source(ESP_SLEEP_WAKEUP_ALL);
Serial.println("Disable all wakeup sources");
    esp_sleep_pd_config(ESP_PD_DOMAIN_RTC_PERIPH, ESP_PD_OPTION_ON);
    Serial.println("Power domain RTC peripheral on");
    esp_wifi_set_ps(WIFI_PS_MIN_MODEM); // Thay thế WIFI_PS_NONE

    Serial.println("setup done");

    // print tất cả các thông số
    Serial.print("SSID: ");
    Serial.println(ssid);
    Serial.print("Password: ");
    Serial.println(password);
    Serial.print("Firebase Database URL: ");
    Serial.println(DATABASE_URL);
    Serial.print("Firebase API Key: ");
    Serial.println(API_KEY);
    Serial.print("Firebase User Email: ");
    Serial.println(USER_EMAIL);
    Serial.print("Firebase User Password: ");
    Serial.println(USER_PASSWORD);
    // print tất cả các trạng thái các biến
    Serial.print("is_led: ");
    Serial.println(is_led);
    Serial.print("is_bom: ");
    Serial.println(is_bom);
    Serial.print("is_fan: ");
    Serial.println(is_fan);
    Serial.print("is_heater: ");
    Serial.println(is_heater);
    // Serial.print("is_ledRgbs: ");
    // Serial.println(is_ledRgbs);
    Serial.print("is_bom: ");
    Serial.println(is_bom);
}

void loop() {
    // Kiểm tra kết nối WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected. Reconnecting...");
        if (wifiState == true) {
            blinkLED(bomKKLow, 2, 500);  // Nhấp nháy 3 lần khi mất kết nối
            wifiState = false;
            if (is_bom == true) {
                digitalWrite(bomKKLow, LOW);
            } else if (is_bom == false) {
                digitalWrite(bomKKLow, HIGH);
            }
        }
        initWifi();
        if (WiFi.status() == WL_CONNECTED) {
            blinkLED(bomKKLow, 2, 100);  // Nhấp nháy 2 lần khi kết nối lại
            if (is_bom == true) {
                digitalWrite(bomKKLow, LOW);
            } else if (is_bom == false) {
                digitalWrite(bomKKLow, HIGH);
            }
        }
    }
    // Kiểm tra kết nối Firebase
    if (Firebase.ready()) {
        checkFirebaseStream(&fbdo_status);
        // checkFirebaseStream(&fbdo_led);
        //        checkFirebaseStream(&fbdo_lamp);
        // checkFirebaseStream(&fbdo_aquarium);
    }
    vTaskDelay(100 / portTICK_PERIOD_MS);  // Thay delay(100) bằng vTaskDelay
    // autoSyncTime();
    // khi hệ thống tự động, chay autoRunSystem
    if (autoSystem) {
        autoRunSystem();
    }
    getTemperatures();
    readDHTSensor();  // Đọc dữ liệu cảm biến DHT11
    // Execute LED effects based on currentEffect
    // if (is_ledRgbs == true) {
    //     executeLEDEffects();
    // }
}



void blinkLED(int pin, int times, int delayTime) {
    for (int i = 0; i < times; i++) {
        digitalWrite(pin, HIGH);
        delay(delayTime);
        digitalWrite(pin, LOW);
        delay(delayTime);
    }
}

/**
 * Hàm chạy hệ thống tự động
 */
void autoRunSystem() {
    if (timeClient.isTimeSet()) {
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);

        int currentHour = timeClient.getHours();
        int currentMinute = timeClient.getMinutes();
        int currentSecond = timeClient.getSeconds();

        //        Serial.println("🕒 Time: " + String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
        //                       String(currentMinute));
        // Cập nhật thời gian lên Firebase vào lúc khởi động
        if (!initTimeUpFirebase) {
            timeClient.forceUpdate();
            currentHour = timeClient.getHours();
            currentMinute = timeClient.getMinutes();
            currentSecond = timeClient.getSeconds();

            //cập nhật cả giây
            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute) + ":" + String(currentSecond);
            Firebase.RTDB.setString(&fbdo, "/aquarium/readtime", currentTime);
            initTimeUpFirebase = true;
        }
        // Chuyển thời gian thành phút để so sánh dễ dàng
        int currentTime = currentHour * 60 + currentMinute;


        // Tự động bật đèn led theo lịch trình hàng ngày
        //bật từ 13:00 - 23:30
        if (currentTime >= 780 && currentTime < 1410) {
            if (!is_led) {
                digitalWrite(LedBeLow, LOW);
                if (!Firebase.RTDB.getBool(&fbdo, "/status/bigLight") || fbdo.boolData() != true) {
                    Firebase.RTDB.setBool(&fbdo, "/status/bigLight", true);
                }

                // Firebase.RTDB.setBool(&fbdo, "/aquarium/bigLight", true);
                is_led = true;
            }
        } else {
            if (is_led) {
                digitalWrite(LedBeLow, HIGH);
                if (Firebase.RTDB.getBool(&fbdo, "/status/bigLight") || fbdo.boolData() != false) {
                    Firebase.RTDB.setBool(&fbdo, "/status/bigLight", false);
                }
                // Firebase.RTDB.setBool(&fbdo, "/aquarium/bigLight", false);
                is_led = false;
            }
        }
        // Tự động bật bơm nước waterPump theo lịch trình hàng ngày
        //  '4:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 3:00',
        bool shouldTurnOn = (currentTime >= 240 && currentTime < 660) ||    // 4:00 - 11:00
                            (currentTime >= 720 && currentTime < 840) ||    // 12:00 - 14:00
                            (currentTime >= 1020 && currentTime < 1200) ||  // 17:00 - 20:00
                            (currentTime >= 1320 || currentTime < 180);     // 22:00 - 3:00
        // Tự động bật bơm oxi theo lịch trình hàng ngày
        if (shouldTurnOn) {
            if (is_bom == false) {
                digitalWrite(bomKKLow, LOW);
                if (!Firebase.RTDB.getBool(&fbdo, "/status/waterPump") || fbdo.boolData() != true) {
                    Firebase.RTDB.setBool(&fbdo, "/status/waterPump", true);
                }
                // Firebase.RTDB.setBool(&fbdo, "/aquarium/waterPump", true);
                is_bom = true;
            }
        } else {
            if (is_bom == true) {
                digitalWrite(bomKKLow, HIGH);
                if (Firebase.RTDB.getBool(&fbdo, "/status/waterPump") || fbdo.boolData() != false) {
                    Firebase.RTDB.setBool(&fbdo, "/status/waterPump", false);
                }
                // Firebase.RTDB.setBool(&fbdo, "/aquarium/waterPump", false);
                is_bom = false;
            }
        }
        // Cập nhật thời gian lên Firebase mỗi 20 phút
        if (currentMinute == 0 || currentMinute == 20 || currentMinute == 40) {
            // if (currentEffect == 0) {
            //     tatDen();
            // }
            timeClient.forceUpdate();
            currentHour = timeClient.getHours();
            currentMinute = timeClient.getMinutes();
            currentSecond = timeClient.getSeconds();

            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute) + ":" + String(currentSecond);
            String timeFromFirebase = "";

            if (Firebase.RTDB.getString(&fbdo, "/aquarium/readtime", &timeFromFirebase)) {
                // Tách phút từ currentTime
                int currentMinSep1 = currentTime.indexOf(":");
                int currentMinSep2 = currentTime.indexOf(":", currentMinSep1 + 1);
                int currentMinuteExtracted = currentTime.substring(currentMinSep1 + 1, currentMinSep2).toInt();

                // Tách phút từ Firebase
                int fbMinSep1 = timeFromFirebase.indexOf(":");
                int fbMinSep2 = timeFromFirebase.indexOf(":", fbMinSep1 + 1);
                int firebaseMinuteExtracted = timeFromFirebase.substring(fbMinSep1 + 1, fbMinSep2).toInt();

                // So sánh phút
                if (currentMinuteExtracted != firebaseMinuteExtracted) {
                    Firebase.RTDB.setString(&fbdo, "/aquarium/readtime", currentTime);
                }
            } else {
                Serial.println("Lỗi khi đọc readtime: " + fbdo.errorReason());
            }

        }
    } else {
        Serial.println("Waiting for NTP time sync...");
        timeClient.forceUpdate();
    }
}

/**
 * Xử lý dữ liệu từ Firebase Stream
 * @param fbdo FirebaseData
 */
void handleFirebaseStream(FirebaseData *fbdo) {
    String path = fbdo->dataPath();
    //    Serial.print("Stream path: ");
    //    Serial.println(path);
    // /status/auto
    Serial.print("Stream path: ");
    Serial.println(path);
    Serial.print("Stream data: ");
    Serial.println(fbdo->stringData());


    if (path == "/auto") {
        autoSystem = fbdo->boolData();
        if (autoSystem == true) {
            is_led = false;
            is_bom = false;
            Firebase.RTDB.setBool(fbdo, "/status/waterPump", false);
            Firebase.RTDB.setBool(fbdo, "/status/bigLight", false);

            digitalWrite(LedBeLow, HIGH);
            digitalWrite(bomKKLow, HIGH);
        }
        //        updateLamp();
    }
        // /lamp/status
        //    else if (path == "/status") {
        //        lampState = fbdo->boolData();
        //        updateLamp();
        //    }
        // /aquarium/bigLight
    else if (path == "/bigLight") {
        is_led = fbdo->boolData();
        if (autoSystem == true) {
            if (is_led == true) {
                // Firebase.RTDB.setBool(fbdo, "/aquarium/bigLight", true);
                Firebase.RTDB.setBool(fbdo, "/status/bigLight", true);
            } else {
                // Firebase.RTDB.setBool(fbdo, "/aquarium/bigLight", false);
                Firebase.RTDB.setBool(fbdo, "/status/bigLight", false);
            }
        } else if (autoSystem == false) {
            if (is_led == true) {
                digitalWrite(LedBeLow, LOW);
                Firebase.RTDB.setBool(fbdo, "/status/bigLight", true);
            } else if (is_led == false) {
                digitalWrite(LedBeLow, HIGH);
                Firebase.RTDB.setBool(fbdo, "/status/bigLight", false);
            }
        }
    }
    else if (path =="/fan") {
        is_fan = fbdo->boolData();
        if (autoSystem == true) {
            if (is_fan == true) {
                Firebase.RTDB.setBool(fbdo, "/status/fan", true);
            } else {
                Firebase.RTDB.setBool(fbdo, "/status/fan", false);
            }
        } else if (autoSystem == false) {
            if (is_fan == true) {
                digitalWrite(FAN_PIN, LOW);
            } else {
                digitalWrite(FAN_PIN, HIGH);
            }
        }
    }
    else if (path =="/heater") {
        is_heater = fbdo->boolData();
        if (autoSystem == true) {
            if (is_heater == true) {
                Firebase.RTDB.setBool(fbdo, "/status/heater", true);
            } else {
                Firebase.RTDB.setBool(fbdo, "/status/heater", false);
            }
        } else if (autoSystem == false) {
            if (is_heater == true) {
                digitalWrite(HEATER_PIN, LOW);
            } else {
                digitalWrite(HEATER_PIN, HIGH);
            }
        }
    }
        // /led/currentEffect
    // else if (path == "/currentEffect") {
    //     currentEffect = fbdo->intData();
    //     if (currentEffect == 0) {
    //         is_ledRgbs = false;
    //         tatDen();

    //     } else {
    //         is_ledRgbs = true;
    //     }
    // }
        //        // /lamp/level
        //    else if (path == "/level") {
        //        levelLampHighState = fbdo->boolData();
        //        updateLamp();
        //    }
        // aquarium/waterPump
    else if (path == "/waterPump") {
        is_bom = fbdo->boolData();
        Serial.print("is_bom: ");
        Serial.println(is_bom);
        //is_bom = true -> LOW (bật bơm)
        if (autoSystem == true) {
            if (is_bom == true) {
                //sửa lại giá trị trên firebase vì đang bật chế độ tự động
                // Firebase.RTDB.setBool(fbdo, "/aquarium/waterPump", true);
                Firebase.RTDB.setBool(fbdo, "/status/waterPump", true);
            } else {
                // Firebase.RTDB.setBool(fbdo, "/aquarium/waterPump", false);
                Firebase.RTDB.setBool(fbdo, "/status/waterPump", false);
            }
        } else if (autoSystem == false) {
            if (is_bom == true) {
                digitalWrite(bomKKLow, LOW);
            } else {
                digitalWrite(bomKKLow, HIGH);
            }
        }
    }
        // /led/brightness
    // else if (path == "/brightness") {
    //     brightness = fbdo->intData();
    //     pixels.setBrightness(brightness);
    // }
        // /aquarium/airPumpSpeed
        // else if (path == "/airPumpSpeed") {
        //     airPumpSpeed = fbdo->intData();
        //     analogWrite(ena, map(airPumpSpeed, 0, 9, 0, 255));
        // }
        // /led/speed
    // else if (path == "/speed") {
    //     speed = fbdo->intData();
    // }
        // /led/color
    // else if (path == "/color") {
    //     FirebaseJson json = fbdo->jsonObject();
    //     FirebaseJsonData jsonData;
    //     int r = 0, g = 0, b = 0;

    //     json.get(jsonData, "r");
    //     if (jsonData.success) {
    //         r = jsonData.to<int>();
    //     }

    //     json.get(jsonData, "g");
    //     if (jsonData.success) {
    //         g = jsonData.to<int>();
    //     }

    //     json.get(jsonData, "b");
    //     if (jsonData.success) {
    //         b = jsonData.to<int>();
    //     }

    //     selectedColor = pixels.Color(r, g, b);
    // }
}

//// Cập nhật trạng thái đèn bàn học
//void updateLamp() {
//    if (lampState == true) {
//        digitalWrite(lamp, LOW);  // Tắt đèn
//    } else {
//        digitalWrite(lamp, HIGH);  // Bật đèn
//    }
//
//    if (levelLampHighState == true) {
//        digitalWrite(levelLampHigh, LOW);  // Tắt đèn
//    } else {
//        digitalWrite(levelLampHigh, HIGH);  // Bật đèn
//    }
//}