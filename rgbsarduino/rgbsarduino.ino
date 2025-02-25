#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <time.h>
#include "config.h"
#include <OneWire.h>
#include <DallasTemperature.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// Cấu hình NTP
// Thay đổi biến global
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "time.google.com", 25200, 60000);  // Sử dụng máy chủ Google NTP

bool autoSystem = true;

#define ONE_WIRE_BUS 23
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
float lastTemperature = -127.00;  // Initialize with an invalid tempe

// Cấu hình Firebase
FirebaseConfig configF;
FirebaseAuth auth;
FirebaseData fbdo;

// Cấu hình NeoPixel
#define LED_PIN 4
#define NUMPIXELS 18
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Biến điều khiển từ Firebase
int brightness = 200;                              // Độ sáng mặc định
int speed = 50;                                    // Tốc độ mặc định
uint32_t selectedColor = pixels.Color(255, 0, 0);  // Màu mặc định (đỏ)
int currentEffect = 0;                             // Hiệu ứng hiện tại

bool is_bom = true;    // Trạng thái máy bơm
bool is_led = true;    // Trạng thái đèn lớn
int airPumpSpeed = 5;  // Tốc độ máy bơm khí

// Các chân GPIO
// const int btn_bom = 9;
const int ena = 5;  // PWM
// const int in1 = 4;
const int in2_bom = 18;  // Điều khiển máy bơm


const int role_led = 19;  // Điều khiển đèn lớn


const int lamp = 21;
const int levelLampHigh = 22;

bool lampState = true;
bool levelLampHighState = true;

// Network credentials
const char *ssid = WIFI_SSID;
const char *password = WIFI_PASSWORD;

// Hàm khởi tạo WiFi
bool initWifi() {
    WiFi.begin(ssid, password);
    unsigned long wifiTimeout = millis() + 10000;  // Giới hạn thời gian 10 giây
    while (WiFi.status() != WL_CONNECTED && millis() < wifiTimeout) {
        delay(500);
        Serial.print(".");
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nConnected to WiFi");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        return true;
    } else {
        Serial.println("\nFailed to connect to WiFi");
        return false;
    }
}

// khởi tạo firebase
void initFirebase() {
    configF.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    configF.database_url = DATABASE_URL;
    configF.token_status_callback = tokenStatusCallback;
    Firebase.begin(&configF, &auth);
    Firebase.reconnectWiFi(true);

    // Bắt đầu stream
    if (!Firebase.RTDB.beginStream(&fbdo, "/")) {
        Serial.printf("Stream setup failed: %s\n", fbdo.errorReason().c_str());
    } else {
        Serial.println("Firebase stream initialized successfully.");
    }
}

// đồng bộ dữ liệu từ firebase
void _syncDataFromFirebase() {

    if (Firebase.RTDB.getBool(&fbdo, "/status/auto")) {
        autoSystem = fbdo.boolData();
    }
    if (Firebase.RTDB.getBool(&fbdo, "/lamp/status")) {
        lampState = fbdo.boolData();
    }
    if (Firebase.RTDB.getBool(&fbdo, "/lamp/level")) {
        levelLampHighState = fbdo.boolData();
    }
    updateLamp();
    // Đọc trạng thái máy bơm
    if (Firebase.RTDB.getBool(&fbdo, "/aquarium/waterPump")) {
        is_bom = fbdo.boolData();
        digitalWrite(in2_bom, is_bom ? HIGH : LOW);
    }

    // Đọc trạng thái đèn lớn
    if (Firebase.RTDB.getBool(&fbdo, "/aquarium/bigLight")) {
        is_led = fbdo.boolData();
        digitalWrite(role_led, is_led ? HIGH : LOW);
    }

    // Đọc tốc độ máy bơm khí
    if (Firebase.RTDB.getInt(&fbdo, "/aquarium/airPumpSpeed")) {
        airPumpSpeed = fbdo.intData();
        analogWrite(ena, map(airPumpSpeed, 0, 9, 0, 255));
    }

    // Đọc dữ liệu LED
    if (Firebase.RTDB.getInt(&fbdo, "/led/currentEffect")) {
        currentEffect = fbdo.intData();
    }
    if (Firebase.RTDB.getInt(&fbdo, "/led/brightness")) {
        brightness = fbdo.intData();
        pixels.setBrightness(brightness);
    }
    if (Firebase.RTDB.getInt(&fbdo, "/led/speed")) {
        speed = fbdo.intData();
    }
    if (Firebase.RTDB.getJSON(&fbdo, "/led/color")) {
        FirebaseJson json = fbdo.jsonObject();
        FirebaseJsonData jsonData;

        json.get(jsonData, "r");
        int r = jsonData.success ? jsonData.to<int>() : 0;

        json.get(jsonData, "g");
        int g = jsonData.success ? jsonData.to<int>() : 0;

        json.get(jsonData, "b");
        int b = jsonData.success ? jsonData.to<int>() : 0;

        selectedColor = pixels.Color(r, g, b);
    }
}

void setup() {
    Serial.println("Starting...");
    Serial.begin(115200);
    Serial.println("1");
    pixels.begin();
    Serial.println("2");
    pixels.setBrightness(brightness);
    Serial.println("3");
    // Khởi tạo các chân GPIO
    //  pinMode(btn_bom, INPUT);
    pinMode(role_led, OUTPUT);
    digitalWrite(role_led, HIGH);
    pinMode(ena, OUTPUT);
    pinMode(in2_bom, OUTPUT);
    pinMode(lamp, OUTPUT);
    digitalWrite(lamp, HIGH);
    pinMode(levelLampHigh, OUTPUT);
    digitalWrite(levelLampHigh, HIGH);

    // Kết nối WiFi và Firebase
    if (initWifi()) {
        Serial.println("WiFi connected");
        delay(2000);
        timeClient.begin();
        timeClient.setTimeOffset(25200);  // 7 hours offset in seconds
        timeClient.forceUpdate();         // Force an initial update

        initFirebase();
        Serial.println("Firebase connected");
        _syncDataFromFirebase();  // Đồng bộ dữ liệu ban đầu
        sensors.begin();          // Start temperature sensor
        updateTemperature();      // Push initial temperature data
    } else {
        Serial.println("Cannot proceed without WiFi connection.");
        while (1) {
            delay(1000);
        }
    }
    Serial.println("setup done");
}

// Cập nhật trạng thái đèn lên Firebase
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

// Cập nhật nhiệt độ lên Firebase
void updateTemperature() {
    float temperature = sensors.getTempCByIndex(0);
    if (temperature != -127.00) {
        Firebase.RTDB.setFloat(&fbdo, "/aquarium/temperature", temperature);
        Serial.print("Updated temperature to Firebase: ");
        Serial.println(temperature);
    }
}

// Hàm thực thi hiệu ứng LED dựa trên currentEffect
void executeLEDEffects() {
    switch (currentEffect) {
        case 0:
            tatDen();
            break;
        case 1:
            pixels.setBrightness(brightness);
            rotatingColors(speed / 5);
            break;
        case 2:
            pixels.setBrightness(brightness);
            nhipDap(speed / 10);
            break;
        case 3:
            pixels.setBrightness(brightness);
            nhipDapWithColor(speed / 10);
            break;
        case 4:
            pixels.setBrightness(brightness);
            nuocChay(selectedColor, speed);
            break;
        case 5:
            pixels.setBrightness(brightness);
            muaRoi(speed, 3);
            break;
        case 6:
            pixels.setBrightness(brightness);
            randomBlink(speed);
            break;
        case 7:
            pixels.setBrightness(brightness);
            strobeEffect(selectedColor, speed);
            break;
        case 8:
            pixels.setBrightness(brightness);
            chaseEffect(selectedColor, speed);
            break;
    }
    pixels.setBrightness(brightness);
}

// Hàm xử lý dữ liệu từ Firebase khi có stream
void handleFirebaseStream() {
    String path = fbdo.dataPath();
    if (path == "/status/auto") {
        autoSystem = fbdo.boolData();
        updateLamp();
    } else if (path == "/lamp/status") {
        lampState = fbdo.boolData();
        updateLamp();
    } else if (path == "/lamp/level") {
        levelLampHighState = fbdo.boolData();
        updateLamp();
    } else if (path == "/aquarium/waterPump") {
        is_bom = fbdo.boolData();
        digitalWrite(in2_bom, is_bom ? HIGH : LOW);
    } else if (path == "/aquarium/bigLight") {
        is_led = fbdo.boolData();
        digitalWrite(role_led, is_led ? HIGH : LOW);
    } else if (path == "/aquarium/airPumpSpeed") {
        airPumpSpeed = fbdo.intData();
        analogWrite(ena, map(airPumpSpeed, 0, 9, 0, 255));
    } else if (path == "/led/currentEffect") {
        currentEffect = fbdo.intData();
    } else if (path == "/led/brightness") {
        brightness = fbdo.intData();
        pixels.setBrightness(brightness);
    } else if (path == "/led/speed") {
        speed = fbdo.intData();
    } else if (path == "/led/color") {
        FirebaseJson json = fbdo.jsonObject();
        FirebaseJsonData jsonData;

        json.get(jsonData, "r");
        int r = jsonData.success ? jsonData.to<int>() : 0;

        json.get(jsonData, "g");
        int g = jsonData.success ? jsonData.to<int>() : 0;

        json.get(jsonData, "b");
        int b = jsonData.success ? jsonData.to<int>() : 0;

        selectedColor = pixels.Color(r, g, b);
    }
}

// biến kiểm tra đã cập nhật thời gian lên Firebase chưa
bool initTimeUpFirebase = false;

// Hàm tự động cập nhật thời gian và chạy hệ thống
void autoRunSystem() {
    timeClient.update();  // Cập nhật thời gian từ server NTP

    if (timeClient.isTimeSet()) {  // Kiểm tra xem thời gian đã được set chưa
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);

        int currentHour = timeClient.getHours();      // Lấy giờ trực tiếp từ NTPClient
        int currentMinute = timeClient.getMinutes();  // Lấy phút trực tiếp từ NTPClient

        Serial.println("🕒 Time: " + String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                       String(currentMinute));

        if (initTimeUpFirebase == false) {
            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute);
            Firebase.RTDB.setString(&fbdo, "/status/time", currentTime);
            initTimeUpFirebase = true;
        }
        // Cập nhật thời gian lên Firebase vào các phút 00 và 30
        if (currentMinute == 0 || currentMinute == 30) {
            String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                                 String(currentMinute);
            Firebase.RTDB.setString(&fbdo, "/status/time", currentTime);
            delay(60000);  // Tránh cập nhật nhiều lần trong cùng một phút
        }

        // Tự động bật đèn bigLight từ 9h-20h hàng ngày
        if (currentHour >= 9 && currentHour < 20) {
            digitalWrite(role_led, HIGH);
            Firebase.RTDB.setBool(&fbdo, "/status/bigLight", true);
        } else {
            digitalWrite(role_led, LOW);
            Firebase.RTDB.setBool(&fbdo, "/status/bigLight", false);
        }

        // Tự động bật bơm nước waterPump theo lịch trình hàng ngày
        if ((currentHour == 4 && currentMinute >= 30) || (currentHour >= 5 && currentHour < 8) ||
            (currentHour >= 9 && currentHour < 12) || (currentHour >= 13 && currentHour < 16) ||
            (currentHour >= 17 && currentHour < 20) || (currentHour >= 21)) {
            if (!is_bom) {
                is_bom = true;
                digitalWrite(in2_bom, HIGH);
                Firebase.RTDB.setBool(&fbdo, "/status/waterPump", true);
            }
        } else {
            if (is_bom) {
                is_bom = false;
                digitalWrite(in2_bom, LOW);
                Firebase.RTDB.setBool(&fbdo, "/status/waterPump", false);
            }
        }
    } else {
        Serial.println("Waiting for NTP time sync...");
        timeClient.forceUpdate();
    }

    delay(1000);
}

void loop() {
    // autoSyncTime();
    if (autoSystem) {
        autoRunSystem();
    }
    delay(10);
    sensors.requestTemperatures();
    float currentTemperature = sensors.getTempCByIndex(
            0);  // Lấy nhiệt độ từ cảm biến DS18B20 (chỉ có 1 cảm biến) 0 là chỉ số của cảm biến nhiệt độ 1

    if (currentTemperature == -127.00) {
        sensors.begin();
        Serial.println("⚠️ Error: DS18B20 sensor not found!");
    } else {
        if (abs(currentTemperature - lastTemperature) > 0.1) {
            Serial.print("🌡️ Temperature: ");
            Serial.print(lastTemperature);
            Serial.print(" - ");
            Serial.print(currentTemperature);
            Serial.println(" °C");
            lastTemperature = currentTemperature;
            updateTemperature();
        }
    }
    if (Firebase.ready()) {
        if (Firebase.RTDB.readStream(&fbdo)) {
            if (fbdo.streamAvailable()) {
                Serial.print("🌡️ có: ");
                handleFirebaseStream();
            }
        }
    }
    // Execute LED effects based on currentEffect
    executeLEDEffects();
}

// Hiệu ứng lấp đầy màu
void nuocChay(uint32_t color, int wait) {
    for (int i = pixels.numPixels(); i >= 0; i--) {
        pixels.setPixelColor(i, color);
        pixels.show();
        delay(wait);
    }
    for (int i = pixels.numPixels(); i >= 0; i--) {
        pixels.setPixelColor(i, 0);
        pixels.show();
        delay(wait);
    }
}

// Hiệu ứng lấp lánh
// wait: thời gian chờ
// iterations: số lần lặp
void muaRoi(int speed, int iterations) {
    for (int iter = 0; iter < iterations; iter++) {
        // Hiệu ứng từ phải sang trái
        for (int i = NUMPIXELS - 1; i >= 0; i--) {
            int rgb1 = random(255);
            int rgb2 = random(255);
            int rgb3 = random(255);

            // Bật pixel với màu ngẫu nhiên
            pixels.setPixelColor(i, pixels.Color(rgb1, rgb2, rgb3));
            pixels.show();
            delay(speed);  // Điều chỉnh tốc độ

            // Tắt pixel
            pixels.setPixelColor(i, pixels.Color(0, 0, 0));
        }

        // Hiệu ứng từ trái sang phải
        for (int i = 0; i < NUMPIXELS; i++) {
            int rgb1 = random(255);
            int rgb2 = random(255);
            int rgb3 = random(255);

            // Bật pixel với màu ngẫu nhiên
            pixels.setPixelColor(i, pixels.Color(rgb1, rgb2, rgb3));
            pixels.show();
            delay(speed);  // Điều chỉnh tốc độ

            // Tắt pixel
            pixels.setPixelColor(i, pixels.Color(0, 0, 0));
        }
    }
}

// Hiệu ứng nhịp đập
void nhipDap(int speed) {
    int rgb1 = random(255);
    int rgb2 = random(255);
    int rgb3 = random(255);
    uint32_t color = pixels.Color(rgb1, rgb2, rgb3);

    // Tăng độ sáng
    for (int j = 0; j < 255; j++) {
        pixels.fill(color, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);  // Sử dụng speed để điều chỉnh tốc độ
    }

    // Giảm độ sáng
    for (int j = 255; j >= 0; j--) {
        pixels.fill(color, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);  // Sử dụng speed để điều chỉnh tốc độ
    }
}

void nhipDapWithColor(int speed) {
    // Tăng độ sáng
    for (int j = 0; j < 255; j++) {
        pixels.fill(selectedColor, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);  // Sử dụng speed để điều chỉnh tốc độ
    }

    // Giảm độ sáng
    for (int j = 255; j >= 0; j--) {
        pixels.fill(selectedColor, 0, NUMPIXELS);
        pixels.setBrightness(j);
        pixels.show();
        delay(speed);  // Sử dụng speed để điều chỉnh tốc độ
    }
}

// tắt đèn
void tatDen() {
    pixels.clear();
    pixels.show();
}

//Hiệu ứng xoay vòng (Rotating Colors)
void rotatingColors(int wait) {
    static uint8_t hue = 0;
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, Wheel((hue + i * 256 / pixels.numPixels()) & 255));
    }
    pixels.show();
    hue++;
    delay(wait);
}

//Hiệu ứng nhấp nháy ngẫu nhiên (Random Blink)
void randomBlink(int wait) {
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, pixels.Color(random(255), random(255), random(255)));
    }
    pixels.show();
    delay(wait);
    pixels.clear();
    pixels.show();
    delay(wait);
}

// Hiệu ứng đuổi màu (Chase Effect)
void chaseEffect(uint32_t color, int wait) {
    for (int i = 0; i < pixels.numPixels(); i++) {
        pixels.setPixelColor(i, color);
        pixels.show();
        delay(wait);
        pixels.setPixelColor(i, 0);
    }
}

// Hiệu ứng lấp lánh theo nhịp (Strobe Effect)
void strobeEffect(uint32_t color, int wait) {

    pixels.fill(color, 0, NUMPIXELS);
    pixels.show();
    delay(wait);
    pixels.clear();
    pixels.show();
    delay(wait);
}

// Hàm hỗ trợ cho hiệu ứng cầu vồng
uint32_t Wheel(byte WheelPos) {
    WheelPos = 255 - WheelPos;
    if (WheelPos < 85) {
        return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
    }
    if (WheelPos < 170) {
        WheelPos -= 85;
        return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
    }
    WheelPos -= 170;
    return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
}