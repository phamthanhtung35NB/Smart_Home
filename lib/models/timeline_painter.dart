import 'package:flutter/material.dart';

class TimelinePainter extends CustomPainter {
  final String schedule;

  TimelinePainter(this.schedule);

//Phương pháp trợ giúp để chuyển đổi chuỗi thời gian (hh: mm) thành phút
  int _convertTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      // Chuyển đổi thành số nguyên, nếu không thành công, trả về 0
      int hours = int.tryParse(parts[0]) ?? 0;
      // Chuyển đổi thành số nguyên, nếu không thành công, trả về 0
      int minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Draw background line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw active segments
    final activePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final timeSlots = schedule.split(', ');
    for (var slot in timeSlots) {
      final times = slot.split(' - ');
      final startTime = _convertTimeToMinutes(times[0]);
      final endTime = _convertTimeToMinutes(times[1]);

      final startX =
          (startTime / 1440) * size.width; // 1440 minutes in 24 hours
      var endX = (endTime / 1440) * size.width;

      // Handle overnight time ranges
      if (endTime < startTime) {
        // Draw from start to midnight
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(size.width, size.height / 2),
          activePaint,
        );

        // Draw from midnight to end
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(endX, size.height / 2),
          activePaint,
        );
      } else {
        // Normal time range within the same day
        canvas.drawLine(
          Offset(startX, size.height / 2),
          Offset(endX, size.height / 2),
          activePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
