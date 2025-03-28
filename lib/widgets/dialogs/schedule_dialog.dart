import 'package:flutter/material.dart';
import 'package:rgbs/models/timeline_painter.dart';

class ScheduleDialog {
  static void show(BuildContext context, String title, String schedule) {
    // Xác định icon và màu sắc dựa trên loại thiết bị
    IconData deviceIcon =
        title.contains("Đèn") ? Icons.lightbulb : Icons.water_drop;
    Color primaryColor =
        title.contains("Đèn") ? Colors.amber.shade700 : Colors.blue.shade700;

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
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                color: Colors.grey.shade700, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Lịch trình hoạt động:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildEnhancedScheduleView(schedule),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                _buildDailyTimeline(schedule),
              ],
            ),
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

  static Widget _buildEnhancedScheduleView(String schedule) {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: schedule.split(', ').map((timeSlot) {
        final times = timeSlot.split(' - ');
        final startTime = _convertTimeToMinutes(times[0]);
        final endTime = _convertTimeToMinutes(times[1]);

        bool isActive = false;
        if (startTime < endTime) {
          isActive = currentTimeInMinutes >= startTime &&
              currentTimeInMinutes < endTime;
        } else {
          isActive = currentTimeInMinutes >= startTime ||
              currentTimeInMinutes < endTime;
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? Colors.green : Colors.grey.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeSlot,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color:
                      isActive ? Colors.green.shade800 : Colors.grey.shade800,
                ),
              ),
              if (isActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Đang hoạt động',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _buildDailyTimeline(String schedule) {
    return Container(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thời gian hoạt động trong ngày:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size(double.infinity, 50),
              painter: TimelinePainter(schedule),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('06:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('12:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('18:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('24:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  static int _convertTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      int hours = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }
}
