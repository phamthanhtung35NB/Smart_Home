import 'package:flutter/material.dart';

class ThresholdDialog {
  static void show(BuildContext context, String title, String thresholds) {
    // Xác định icon và màu sắc dựa trên loại thiết bị
    IconData deviceIcon = title == 'Quạt' ? Icons.air : Icons.whatshot;
    Color primaryColor = title == 'Quạt' ? Colors.blue.shade700 : Colors.orange;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(deviceIcon, color: primaryColor),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: primaryColor.withOpacity(0.5), width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngưỡng nhiệt độ:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (title == 'Quạt')
                        _buildThresholdItem('Bật khi', '≥ 27.2°C', Colors.red),
                      if (title == 'Quạt')
                        _buildThresholdItem(
                            'Tắt khi', '≤ 26.3°C', Colors.green),
                      if (title == 'Sưởi')
                        _buildThresholdItem('Bật khi', '≤ 22°C', Colors.blue),
                      if (title == 'Sưởi')
                        _buildThresholdItem('Tắt khi', '≥ 24°C', Colors.green),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              _buildTemperatureBar(title),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Đóng',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildThresholdItem(
      String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTemperatureBar(String deviceType) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          if (deviceType == 'Quạt') ...[
            Positioned(
              left: 200, // Ước tính vị trí cho 26.5°C
              top: 0,
              child: _buildTemperatureMarker('26.5°C', 'Bật'),
            ),
            Positioned(
              left: 160, // Ước tính vị trí cho 25.5°C
              bottom: 5,
              child: _buildTemperatureMarker('25.5°C', 'Tắt'),
            ),
          ],
          if (deviceType == 'Sưởi') ...[
            Positioned(
              left: 70, // Ước tính vị trí cho 22°C
              top: 0,
              child: _buildTemperatureMarker('22°C', 'Bật'),
            ),
            Positioned(
              left: 100, // Ước tính vị trí cho 24°C
              bottom: 0,
              child: _buildTemperatureMarker('24°C', 'Tắt'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildTemperatureMarker(String temp, String action) {
    Color color = action == 'Bật' ? Colors.green : Colors.red;
    return Column(
      children: [
        Container(
          width: 2,
          height: 10,
          color: Colors.black,
        ),
        Text(
          temp,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          action,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
