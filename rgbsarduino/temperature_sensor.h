#ifndef TEMPERATURE_SENSOR_H
#define TEMPERATURE_SENSOR_H

#include <DallasTemperature.h>
#include "config.h"

void updateTemperature(FirebaseData *fbdo, float temperature) {
    if (temperature != -127.00) {
        if (temperature >= 26.5) {
            Firebase.RTDB.setString(fbdo, "/status/warning", "⚠️ Đang làm mát");
        } else if (temperature <= 22.0) {
            Firebase.RTDB.setString(fbdo, "/status/warning", "⚠️ Đang sưởi bể!");
        } else {
            Firebase.RTDB.setString(fbdo, "/status/warning", "Nhiệt độ ổn định");
        }

        Firebase.RTDB.setFloat(fbdo, "/aquarium/temperature", temperature);
        Firebase.RTDB.setFloat(fbdo, "/aquarium/temperatureOld", lastTemperature);
        lastTemperature = temperature;

        timeClient.forceUpdate();
        String currentTime = String(timeClient.getHours()) + ":" +
                             (timeClient.getMinutes() < 10 ? "0" : "") + String(timeClient.getMinutes()) + ":" +
                             String(timeClient.getSeconds());
        Firebase.RTDB.setString(fbdo, "/aquarium/time", currentTime);

        // Control fan and heater with hysteresis
        if (autoSystem) {
            // Điều khiển quạt
            if (temperature >= 26.5 && !is_fan) {  // Chỉ bật nếu chưa bật
                digitalWrite(FAN_PIN, LOW);
                is_fan = true;
                Firebase.RTDB.setBool(fbdo, "/status/fan", true);
            } else if (temperature <= 25.5 && is_fan) {  // Chỉ tắt nếu đang bật
                digitalWrite(FAN_PIN, HIGH);
                is_fan = false;
                Firebase.RTDB.setBool(fbdo, "/status/fan", false);
            }

            // Điều khiển sưởi
            if (temperature <= 22 && !is_heater) {
                digitalWrite(HEATER_PIN, LOW);
                is_heater = true;
                Firebase.RTDB.setBool(fbdo, "/status/heater", true);
            } else if (temperature >= 24 && is_heater) {
                digitalWrite(HEATER_PIN, HIGH);
                is_heater = false;
                Firebase.RTDB.setBool(fbdo, "/status/heater", false);
            }
        }
    }
}


void getTemperatures() {
    sensors.requestTemperatures();
    float temperatureC = sensors.getTempCByIndex(0);
    if (temperatureC == -127.00) {
              // Firebase.RTDB.setFloat(&fbdo, "/aquarium/temperature", -99999);
        Serial.println("⚠️ Error: DS18B20 sensor not found!");
        return;  // Thoát khỏi hàm nếu cảm biến lỗi
    
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