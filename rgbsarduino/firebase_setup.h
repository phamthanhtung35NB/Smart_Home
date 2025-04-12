#ifndef FIREBASE_SETUP_H
#define FIREBASE_SETUP_H

#include <Firebase_ESP_Client.h>
#include "config.h"

//void updateLamp();  // Declare updateLamp function
void handleFirebaseStream(FirebaseData *fbdo);  // Declare handleFirebaseStream function

/**
 * Khởi tạo Firebase
 *
 * Callback khi token hết hạn
 * @param status
 * @param id
 */
void initFirebase() {
    configF.api_key = API_KEY;
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    configF.database_url = DATABASE_URL;
    configF.token_status_callback = tokenStatusCallback;
    Firebase.begin(&configF, &auth);
    Firebase.reconnectWiFi(true);

    Serial.println("Initializing Firebase Streams...");

    bool success = true;

    success &= Firebase.RTDB.beginStream(&fbdo_status, "/status");
    success &= Firebase.RTDB.beginStream(&fbdo_led, "/led");

    if (!success) {
        Serial.printf("Stream setup failed: %s\n", fbdo_status.errorReason().c_str());
    } else {
        Serial.println("Firebase streams initialized successfully.");
    }
}

/**
 * Đồng bộ dữ liệu từ Firebase khi vừa kết nối
 * @param fbdo FirebaseData
 */
void _syncDataFromFirebase(FirebaseData *fbdo) {
    if (Firebase.RTDB.getBool(fbdo, "/status/auto")) {
        autoSystem = fbdo->boolData();
    }
    if (Firebase.RTDB.getBool(fbdo, "/status/bigLight")) {
        is_led = fbdo->boolData();
        digitalWrite(LedBeLow, is_led ? LOW : HIGH);
    }
    if (Firebase.RTDB.getBool(fbdo, "/status/waterPump")) {
        is_bom = fbdo->boolData();
        digitalWrite(bomKKLow, is_bom ? LOW : HIGH);
    }
    if (Firebase.RTDB.getBool(fbdo, "/status/fan")) {
        is_fan = fbdo->boolData();
        digitalWrite(FAN_PIN, is_bom ? LOW : HIGH);
    }
    if (Firebase.RTDB.getBool(fbdo, "/status/heater")) {
        is_heater = fbdo->boolData();
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

/**
 * Xử lý dữ liệu từ Firebase Stream
 * @param fbdo FirebaseData
 */
void checkFirebaseStream(FirebaseData *fbdo) {
    if (Firebase.RTDB.readStream(fbdo)) {
        if (fbdo->streamAvailable()) {
//            Serial.printf("New data from %s: %s\n", fbdo->dataPath().c_str(),
//                          fbdo->stringData().c_str());
            handleFirebaseStream(fbdo);
        }
    } else {
        Serial.printf("Stream error (%s): %s\n", fbdo->dataPath().c_str(),
                      fbdo->errorReason().c_str());
    }
}

#endif