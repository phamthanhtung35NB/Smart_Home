#ifndef DH11_SENSOR_H
#define DH11_SENSOR_H

#include <config.h>
void updateDHTSensor(float h, float t, float f, float hic, float hif) {
    if (abs(h - h0) >= 1.0) {
        //ép kiểu phải update dữ liệu lên firebase là float
        if (h==0||h==0.00){
          Firebase.RTDB.setFloat(&fbdo, "/dht/humidity", 0.0);
        }
        Firebase.RTDB.setFloat(&fbdo, "/dht/humidity", h*1.01);
        h0 = h;
    }
    if (abs(t - t0) >= 1.1) {
        Firebase.RTDB.setFloat(&fbdo, "/dht/temperatureC", t);
        Firebase.RTDB.setFloat(&fbdo, "/dht/temperatureF", f);
        Firebase.RTDB.setFloat(&fbdo, "/dht/heatIndexC", hic);
        Firebase.RTDB.setFloat(&fbdo, "/dht/heatIndexF", hif);
        t0 = t;
    }
}

void readDHTSensor() {
    float h = dht.readHumidity();
    float t = dht.readTemperature();
    float f = dht.readTemperature(true);

    if (isnan(h) || isnan(t) || isnan(f)) {
        Serial.println("Failed to read from DHT sensor!");
        return;
    }

    float hif = dht.computeHeatIndex(f, h);
    float hic = dht.computeHeatIndex(t, h, false);

    Serial.print("Độ ẩm:         ");
    Serial.print(h);
    Serial.println(" %t");
    Serial.print("Nhiệt độ:      ");
    Serial.print(t);
    Serial.print(" *C ");
    Serial.print(f);
    Serial.println(" *Ft");
    Serial.print("Chỉ số nhiệt:  ");

    Serial.print(hic);
    Serial.print(" *C ");
    Serial.print(hif);
    Serial.println(" *F");
    updateDHTSensor(h, t, f, hic, hif);
}
#endif