import 'package:flutter/material.dart';
class DHT11HumidityCard extends StatelessWidget {
  final double humidity;
  final double dhtTemperatureC;
  final double heatIndexC;

  DHT11HumidityCard({
    required this.humidity,
    required this.dhtTemperatureC,
    required this.heatIndexC,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text(
                      'Độ ẩm không khí',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${humidity.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: humidity < 40
                        ? Colors.orange
                        : humidity > 70
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 5,
              endIndent: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thermostat_outlined, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      'Nhiệt độ không khí',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${dhtTemperatureC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: dhtTemperatureC < 22
                        ? Colors.blue
                        : dhtTemperatureC > 30
                            ? Colors.red
                            : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(
              color: Colors.grey,
              thickness: 1,
              indent: 5,
              endIndent: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 10),
                    Text(
                      'Nhiệt độ cảm nhận',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${heatIndexC.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: heatIndexC < 22
                        ? Colors.blue
                        : heatIndexC > 30
                            ? Colors.deepOrange
                            : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}