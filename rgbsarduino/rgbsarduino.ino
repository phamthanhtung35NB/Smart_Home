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

// Cấu hình thời gian
// Cấu hình NTP
// Thay đổi biến global
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "time.google.com", 25200, 60000);  // Sử dụng máy chủ Google NTP

// Biến kiểm tra hệ thống tự động măc định là tự động
bool autoSystem = true;

// Cấu hình cảm biến nhiệt độ DS18B20
#define ONE_WIRE_BUS 23
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
float lastTemperature = -127.00;  // Initialize with an invalid tempe

// Cấu hình WiFi
const char *ssid = WIFI_SSID;
const char *password = WIFI_PASSWORD;

// Cấu hình Firebase
FirebaseConfig configF;
FirebaseAuth auth;
FirebaseData fbdo;
FirebaseData fbdo_status;
FirebaseData fbdo_led;
FirebaseData fbdo_lamp;
FirebaseData fbdo_aquarium;


// Cấu hình NeoPixel led rgb
#define LED_PIN 4
#define NUMPIXELS 18
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Khởi tạo trạng thái ban đầu trước khi update data từ Firebase
int brightness = 200;                              // Độ sáng mặc định
int speed = 50;                                    // Tốc độ mặc định
uint32_t selectedColor = pixels.Color(255, 0, 0);  // Màu mặc định (đỏ)
int currentEffect = 0;                             // Hiệu ứng hiện tại

bool is_bom = true;              // Trạng thái máy bơm
bool is_led = true;              // Trạng thái đèn lớn
bool lampState = true;           // Trạng thái đèn bàn học
bool levelLampHighState = true;  // Trạng thái đèn bàn học kích hoạt tăng cường sáng
bool wifiState = false;          // Trạng thái wifi

int airPumpSpeed = 5;  // Tốc độ máy bơm khí
// const int btn_bom = 9;
const int ena = 5;  // PWM pin for air pump
// const int in1 = 4;
const int bomKKLow = 18;       // Điều khiển máy bơm (bơm khí)
const int LedBeLow = 19;       // Điều khiển đèn bể cá
const int lamp = 21;           // Điều khiển đèn bàn học
const int levelLampHigh = 22;  // Điều khiển đèn bàn học kích hoạt tăng cường sáng

/**
 * Khởi tạo wifi
 * sẽ luôn chạy cho đến khi kết nối thành công
 * @return bool
 */
bool initWifi() {
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\nConnected to WiFi");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP());
        wifiState = true;
        return true;
    } else {
        Serial.println("\nFailed to connect to WiFi");
        return false;
    }
}

/**
 * Hàm callback khi token hết hạn và khơi tạo lại token \\ khởi tạo lại token
 * @param error
 * @return void
 */
void initTimeClient() {
    timeClient.begin();
    timeClient.setTimeOffset(25200);  // 7 hours offset in seconds
    timeClient.forceUpdate();         //  Cập nhật thời gian từ server NTP ngay lập tức
}

/**
 * Hàm callback khi token hết hạn và khơi tạo lại token
 * @param error
 * @return void
 */
void initFirebase() {
    configF.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    configF.database_url = DATABASE_URL;
    configF.token_status_callback = tokenStatusCallback;
    Firebase.begin(&configF, &auth);
    Firebase.reconnectWiFi(true);

    // Bắt đầu stream
    //    15:38:51.392 -> > ERROR.available: Cannot operate on a closed SSL connection.
    //    15:38:51.392 -> > ERROR.available: Incoming record is too large to be processed, or buffer is too small for the handshake message to send.
    // Bắt đầu stream cho các node cần thiết
    Serial.println("Initializing Firebase Streams...");

    bool success = true;

    success &= Firebase.RTDB.beginStream(&fbdo_status, "/status");
    success &= Firebase.RTDB.beginStream(&fbdo_led, "/led");
    success &= Firebase.RTDB.beginStream(&fbdo_lamp, "/lamp");
    success &= Firebase.RTDB.beginStream(&fbdo_aquarium, "/aquarium");

    if (!success) {
        Serial.printf("Stream setup failed: %s\n", fbdo_status.errorReason().c_str());
    } else {
        Serial.println("Firebase streams initialized successfully.");
    }
}

/**
 * Hàm đồng bộ dữ liệu từ Firebase
 * @return void
 */
void _syncDataFromFirebase(FirebaseData *fbdo) {
    if (Firebase.RTDB.getBool(fbdo, "/status/auto")) {
        autoSystem = fbdo->boolData();
    }
    if (Firebase.RTDB.getBool(fbdo, "/lamp/status")) {
        lampState = fbdo->boolData();
        updateLamp();
    }
    if (Firebase.RTDB.getBool(fbdo, "/lamp/level")) {
        levelLampHighState = fbdo->boolData();
        updateLamp();
    }
    if (Firebase.RTDB.getBool(fbdo, "/aquarium/waterPump")) {
        is_bom = fbdo->boolData();
        digitalWrite(bomKKLow, is_bom ? LOW : HIGH);
    }
    if (Firebase.RTDB.getBool(fbdo, "/aquarium/bigLight")) {
        is_led = fbdo->boolData();
        digitalWrite(LedBeLow, is_led ? LOW : HIGH);
    }
    if (Firebase.RTDB.getInt(fbdo, "/aquarium/airPumpSpeed")) {
        airPumpSpeed = fbdo->intData();
        analogWrite(ena, map(airPumpSpeed, 0, 9, 0, 255));
    }
    if (Firebase.RTDB.getInt(fbdo, "/led/currentEffect")) {
        currentEffect = fbdo->intData();
    }
    if (Firebase.RTDB.getInt(fbdo, "/led/brightness")) {
        brightness = fbdo->intData();
        pixels.setBrightness(brightness);
    }
    if (Firebase.RTDB.getInt(fbdo, "/led/speed")) {
        speed = fbdo->intData();
    }
    if (Firebase.RTDB.getJSON(fbdo, "/led/color")) {
        FirebaseJson json = fbdo->jsonObject();
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

        updateTemperature(&fbdo);  // Truyền tham số fbdo
        Serial.println("Initial temperature data pushed");
    } else {
        Serial.println("Cannot proceed without WiFi connection.");
        initWifi();
    }
    Serial.println("setup done");
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

// Cập nhật nhiệt độ lên Firebase
void updateTemperature(FirebaseData *fbdo) {
    float temperature = sensors.getTempCByIndex(0);
    if (temperature != -127.00) {
        Firebase.RTDB.setFloat(fbdo, "/aquarium/temperature", temperature);
        //up date thơi gian
        timeClient.forceUpdate();
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);
        int currentHour = timeClient.getHours();
        int currentMinute = timeClient.getMinutes();
        int currentSecond = timeClient.getSeconds();
        String currentTime =
                String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                String(currentMinute) + ":" + String(currentSecond);
        Firebase.RTDB.setString(fbdo, "/aquarium/time", currentTime);
        Serial.print("Updated temperature to Firebase: ");
        Serial.println(temperature);
    }
}


/**
 * Hàm xử lý dữ liệu từ Firebase stream
 * @return void
 */
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


// biến kiểm tra đã cập nhật thời gian lên Firebase chưa
bool initTimeUpFirebase = false;

/**
 * Hàm tự động chạy hệ thống
 *  cập nhật thời gian, bật đèn, bật bơm nước
 * @return void
 */

void autoRunSystem() {
    if (timeClient.isTimeSet()) {
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);

        int currentHour = timeClient.getHours();
        int currentMinute = timeClient.getMinutes();
        int currentSecond = timeClient.getSeconds();

        Serial.println("🕒 Time: " + String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                       String(currentMinute));

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
    } else {
        Serial.println("Waiting for NTP time sync...");
        timeClient.forceUpdate();
    }
}


/**
 * Hàm lấy nhiệt độ từ cảm biến DS18B20
 * Update nhiệt độ lên Firebase nếu có sự thay đổi
 * @return void
 */
void getTemperatures() {
    sensors.requestTemperatures();
    float currentTemperature = sensors.getTempCByIndex(0);
    if (currentTemperature == -127.00) {
        sensors.begin();
        Serial.println("⚠️ Error: DS18B20 sensor not found!");
    } else {
        if (abs(currentTemperature - lastTemperature) > 0.1) {
            Serial.print("🌡️ Temperature: ");
            Serial.print(lastTemperature);
            Serial.print(" -> ");
            Serial.print(currentTemperature);
            Serial.println(" °C");

            lastTemperature = currentTemperature;
            updateTemperature(&fbdo);  // Truyền tham số fbdo
        }
    }
}


void blinkLED(int pin, int times, int delayTime) {
    for (int i = 0; i < times; i++) {
        digitalWrite(pin, LOW);
        delay(delayTime);
        digitalWrite(pin, HIGH);
        delay(delayTime);
    }
}

void checkFirebaseStream(FirebaseData *fbdo) {
    if (Firebase.RTDB.readStream(fbdo)) {
        if (fbdo->streamAvailable()) {
            Serial.printf("New data from %s: %s\n", fbdo->dataPath().c_str(),
                          fbdo->stringData().c_str());
            handleFirebaseStream(fbdo);
        }
    } else {
        Serial.printf("Stream error (%s): %s\n", fbdo->dataPath().c_str(),
                      fbdo->errorReason().c_str());
    }
}

void loop() {
    // Kiểm tra kết nối WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected. Reconnecting...");
        if (wifiState == true) {
            blinkLED(LedBeLow, 3, 500);  // Nhấp nháy 3 lần khi mất kết nối
            wifiState = false;
        }
        initWifi();
        if (WiFi.status() == WL_CONNECTED) {
            blinkLED(LedBeLow, 2, 500);  // Nhấp nháy 2 lần khi kết nối lại
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
        case 9:  // Single color effect
            pixels.setBrightness(brightness);
            singleColor(selectedColor);
            break;
        case 10:  // Random colors effect
            pixels.setBrightness(brightness);
            randomColors(speed);
            break;
        case 11:  // Smooth random colors effect
            pixels.setBrightness(brightness);
            smoothRandomColors(speed);
            break;
    }
    pixels.setBrightness(brightness);
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

// Function to set all LEDs to a single color
void singleColor(uint32_t color) {
    for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, color);
    }
    pixels.show();
}

// Function to set all LEDs to random colors and change them at a specified speed
void randomColors(int wait) {

    uint32_t colllor = pixels.Color(random(255), random(255), random(255));
    for (int i = 0; i < NUMPIXELS; i++) {
        pixels.setPixelColor(i, colllor);
    }
    pixels.show();
    delay(wait);
}

void smoothRandomColors(int wait) {
    uint32_t currentColor = pixels.Color(random(255), random(255), random(255));
    uint32_t nextColor = pixels.Color(random(255), random(255), random(255));

    for (int j = 0; j < 256; j++) {
        uint8_t r =
                ((uint8_t)(currentColor >> 16) * (255 - j) + (uint8_t)(nextColor >> 16) * j) / 255;
        uint8_t g =
                ((uint8_t)(currentColor >> 8) * (255 - j) + (uint8_t)(nextColor >> 8) * j) / 255;
        uint8_t b = ((uint8_t)(currentColor) * (255 - j) + (uint8_t)(nextColor) * j) / 255;
        uint32_t color = pixels.Color(r, g, b);

        for (int i = 0; i < NUMPIXELS; i++) {
            pixels.setPixelColor(i, color);
        }
        pixels.show();
        delay(wait / 256);
    }
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