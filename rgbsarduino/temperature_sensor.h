#ifndef TEMPERATURE_SENSOR_H
#define TEMPERATURE_SENSOR_H

#include <DallasTemperature.h>
#include "config.h"

void updateTemperature(FirebaseData *fbdo, float temperature) {
    if (temperature != -127.00) {
        Firebase.RTDB.setFloat(fbdo, "/aquarium/temperature", temperature);
        Firebase.RTDB.setFloat(fbdo, "/aquarium/temperatureOld", lastTemperature);
        lastTemperature = temperature;
        timeClient.forceUpdate();
        unsigned long epochTime = timeClient.getEpochTime();
        struct tm *ptm = gmtime((time_t * ) & epochTime);
        int currentHour = timeClient.getHours();
        int currentMinute = timeClient.getMinutes();
        int currentSecond = timeClient.getSeconds();
        String currentTime = String(currentHour) + ":" + (currentMinute < 10 ? "0" : "") +
                             String(currentMinute) + ":" + String(currentSecond);
        Firebase.RTDB.setString(fbdo, "/aquarium/time", currentTime);
        // Firebase.RTDB.setInt(fbdo, "/aquarium/epochTime", epochTime);
    }
}

void getTemperatures() {
    sensors.requestTemperatures();
    float temperatureC = sensors.getTempCByIndex(0);
    if (temperatureC == -127.00) {
        sensors.begin();
        Serial.println("⚠️ Error: DS18B20 sensor not found!");
    } else {
        if (abs(temperatureC - lastTemperature) > 0.1) {
            Serial.print("🌡️ Temperature: ");
            Serial.print(lastTemperature);
            Serial.print(" -> ");
            Serial.print(temperatureC);
            Serial.println(" °C");
            updateTemperature(&fbdo, temperatureC);  // Truyền tham số fbdo
        }
    }
}

#endif