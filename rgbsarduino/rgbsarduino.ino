#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <time.h>
#include "config.h"

// Cấu hình NeoPixel
#define LED_PIN 4  // Đổi sang GPIO4

#define NUMPIXELS 18
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Firebase configuration
FirebaseConfig configF;
FirebaseAuth auth;
FirebaseData fbdo;

// Biến điều khiển từ Firebase
int brightness = 200; // Độ sáng mặc định
int speed = 50;       // Tốc độ mặc định
uint32_t selectedColor = pixels.Color(255, 0, 0); // Màu mặc định (đỏ)

// Network credentials
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

int currentEffect = 2; // Hiệu ứng hiện tại
int totalEffects = 10;  // Tổng số hiệu ứng

bool initWifi() {
  WiFi.begin(ssid, password);
  unsigned long wifiTimeout = millis() + 10000; // Giới hạn thời gian 10 giây
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

void syncTime() {
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");

  struct tm timeinfo;
  int retry = 10; // Số lần thử tối đa

  while (retry-- > 0) {
    if (getLocalTime(&timeinfo)) {
      Serial.println("Time synchronized successfully");
      return;
    }
    Serial.println("Retrying time sync...");
    delay(2000);
  }

  Serial.println("Failed to obtain time after multiple attempts");
}


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
void setup() {
  Serial.begin(115200);
  pixels.begin();
  pixels.setBrightness(200);
pinMode(LED_PIN, OUTPUT);
  // syncTime(); // Đồng bộ hóa thời gian
  if (initWifi()) {
    delay(2000);  // Chờ WiFi ổn định
  syncTime();
    initFirebase();
  } else {
    Serial.println("Cannot proceed without WiFi connection.");
    while (1) {
      delay(1000);
    }
  }
}

void loop() {
  if (Firebase.ready()) {
    // Kiểm tra stream
    if (Firebase.RTDB.readStream(&fbdo)) {
      if (fbdo.streamAvailable()) {
        String eventType = fbdo.eventType();
        String path = fbdo.dataPath();

        // Xử lý dữ liệu theo đường dẫn
        if (path == "/currentEffect") {
          currentEffect = fbdo.intData();
          Serial.printf("Effect changed to: %d\n", currentEffect);
        } else if (path == "/brightness") {
          brightness = fbdo.intData();
          pixels.setBrightness(brightness);
          Serial.printf("Brightness set to: %d\n", brightness);
        } else if (path == "/speed") {
          speed = fbdo.intData();
          Serial.printf("Speed set to: %d\n", speed);
        } else if (path == "/color") {
          FirebaseJson json = fbdo.jsonObject();
          FirebaseJsonData jsonData;

          // Lấy giá trị màu đỏ (r)
          json.get(jsonData, "r");
          int r = jsonData.success ? jsonData.to<int>() : 0;

          // Lấy giá trị màu xanh lá (g)
          json.get(jsonData, "g");
          int g = jsonData.success ? jsonData.to<int>() : 0;

          // Lấy giá trị màu xanh dương (b)
          json.get(jsonData, "b");
          int b = jsonData.success ? jsonData.to<int>() : 0;

          selectedColor = pixels.Color(r, g, b);
          Serial.printf("Color set to: R=%d, G=%d, B=%d\n", r, g, b);
        }
      }
    } else {
      Serial.printf("Stream error: %s\n", fbdo.errorReason().c_str());
    }
  }

  // Giới hạn hiệu ứng trong phạm vi hợp lệ
  if (currentEffect > totalEffects) {
    currentEffect = 0;
  }

  // Thực thi hiệu ứng
  switch (currentEffect) {
    case 0:
      cauVong(speed);
      break;
    case 1:
      nuocChay(selectedColor, speed);
      break;
    case 2:
      muaRoi(speed, 1);
      break;
    case 3:
      nhipDap(1);
      break;
    case 4:
      tatDen();
      break;
    case 5:
      colorWave(speed);
      break;
    case 6:
      rotatingColors(speed);
      break;
    case 7:
      randomBlink(speed);
      break;
    case 8:
      chaseEffect(selectedColor, speed);
      break;
    case 9:
      gradientFade(speed);
      break;
    case 10:
      strobeEffect(selectedColor, speed);
      break;
  }
}

// Hiệu ứng cầu vồng
void cauVong(uint8_t wait) {
  uint16_t i, j;
  for (j = 256; j >= 0; j--) {
    for (i = 0; i < pixels.numPixels(); i++) {
      pixels.setPixelColor(i, Wheel(((i * 256 / pixels.numPixels()) + j) & 255));
    }
    pixels.show();
    delay(wait);
  }
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
void muaRoi(int wait, int iterations) {
  for (int i = NUMPIXELS - 1; i >= 0; i--) {
    int pixel = i;
    int rgb1 = random(255);
    int rgb2 = random(255);
    int rgb3 = random(255);
    pixels.setPixelColor(pixel, pixels.Color(rgb1, rgb2, rgb3));
    pixels.show();
    delay(wait);
    pixels.setPixelColor(pixel, pixels.Color(0, 0, 0));
  }
  for (int i = 0; i < NUMPIXELS; i++) {
    int pixel = i;
    int rgb1 = random(255);
    int rgb2 = random(255);
    int rgb3 = random(255);
    pixels.setPixelColor(pixel, pixels.Color(rgb1, rgb2, rgb3));
    pixels.show();
    delay(wait);
    pixels.setPixelColor(pixel, pixels.Color(0, 0, 0));
  }
}

// Hiệu ứng nhịp đập
void nhipDap(int iterations) {
  for (int i = 0; i < iterations; i++) {
    int rgb1 = random(255);
    int rgb2 = random(255);
    int rgb3 = random(255);
    for (int j = 0; j < 255; j++) {
      pixels.fill(pixels.Color(rgb1, rgb2, rgb3), 0, NUMPIXELS);
      pixels.setBrightness(j);
      pixels.show();
      delay(10);
    }
    for (int j = 255; j >= 0; j--) {
      pixels.fill(pixels.Color(rgb1, rgb2, rgb3), 0, NUMPIXELS);
      pixels.setBrightness(j);
      pixels.show();
      delay(10);
    }
  }
}

// Hiệu ứng tắt đèn
void tatDen() {
  pixels.clear();
  pixels.show();
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
// Hiệu ứng sóng màu (Color Wave)
void colorWave(int wait) {
  for (int i = 0; i < pixels.numPixels(); i++) {
    pixels.setPixelColor(i, Wheel((i * 256 / pixels.numPixels()) & 255));
  }
  pixels.show();
  delay(wait);
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
// Hiệu ứng gradient màu (Gradient Fade)
void gradientFade(int wait) {
  for (int j = 0; j < 256; j++) {
    for (int i = 0; i < pixels.numPixels(); i++) {
      pixels.setPixelColor(i, Wheel((i * 256 / pixels.numPixels() + j) & 255));
    }
    pixels.show();
    delay(wait);
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

