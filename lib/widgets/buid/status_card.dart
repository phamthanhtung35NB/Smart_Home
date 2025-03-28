// status_card.dart
import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String thietBi;
  final bool status;
  final bool autoSystem;
  final Function(String, dynamic) updateDatabase;
  final String schedule;
  final VoidCallback onTap;

  StatusCard({
    required this.title,
    required this.thietBi,
    required this.status,
    required this.autoSystem,
    required this.updateDatabase,
    required this.schedule,
    required this.onTap,
  });

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

  // hàm này sẽ trả về thời gian còn lại cho sự kiện tiếp theo
  String _getTimeUntilNextEvent(
      String schedule, int currentTimeInMinutes, bool isOn) {
    final times = schedule.split(', ').map((time) {
      final parts = time.split(' - ');
      return isOn
          ? _convertTimeToMinutes(parts[1])
          : _convertTimeToMinutes(parts[0]);
    }).toList();

    times.sort();
    for (final time in times) {
      if (currentTimeInMinutes < time) {
        final difference = time - currentTimeInMinutes;
        return '${difference ~/ 60} Giờ ${difference % 60} Phút';
      }
    }
    final difference = (24 * 60 - currentTimeInMinutes) + times.first;
    return '${difference ~/ 60} Giờ ${difference % 60} Phút';
  }

  // Hàm này sẽ trả về thời gian kể từ sự kiện cuối cùng
  String _getTimeSinceLastEvent(String schedule, int currentTimeInMinutes) {
    final times = schedule.split(', ').map((time) {
      final parts = time.split(' - ');
      return _convertTimeToMinutes(parts[1]);
    }).toList();

    if (times.isEmpty) {
      return '0 Phút'; // Trả về giá trị mặc định nếu danh sách trống
    }

    times.sort();
    for (final time in times.reversed) {
      if (currentTimeInMinutes >= time) {
        final difference = currentTimeInMinutes - time;
        return '${difference ~/ 60} Giờ ${difference % 60} Phút';
      }
    }
    return '0 Phút';
  }

  String _getNextChangeTime(String schedule, bool status) {
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    final times = schedule.split(', ').map((time) {
      final parts = time.split(' - ');
      return status
          ? _convertTimeToMinutes(parts[1])
          : _convertTimeToMinutes(parts[0]);
    }).toList();

    times.sort();
    int nextChangeTimeInMinutes = -1;

    // Tìm thời gian tiếp theo
    for (final time in times) {
      if (currentTimeInMinutes < time) {
        nextChangeTimeInMinutes = time;
        break;
      }
    }

    // Nếu không tìm thấy lần tiếp theo hôm nay, hãy sử dụng thời gian đầu tiên của ngày mai
    if (nextChangeTimeInMinutes == -1) {
      nextChangeTimeInMinutes = times.first;
    }

    // Convert minutes to hours and minutes
    int hours = nextChangeTimeInMinutes ~/ 60;
    int minutes = nextChangeTimeInMinutes % 60;

    // Định dạng thời gian
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    String timeElapsed = '';
    String timeRemaining = '';

    final now = DateTime.now();
    // Chuyển đổi thời gian hiện tại thành phút
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    if (status) {
      //Chức năng hiện đang bật, tính thời gian cho đến khi nó tắt
      timeRemaining =
          _getTimeUntilNextEvent(schedule, currentTimeInMinutes, true);
    } else {
      //Chức năng hiện đang tắt, tính thời gian kể từ khi nó tắt và thời gian cho đến khi nó bật
      timeElapsed = _getTimeSinceLastEvent(schedule, currentTimeInMinutes);
      timeRemaining =
          _getTimeUntilNextEvent(schedule, currentTimeInMinutes, false);
    }

    return GestureDetector(
      onTap: onTap, // Add this line
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Trạng thái: ",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        status ? 'Bật' : 'Tắt',
                        style: TextStyle(
                          fontSize: 15,
                          color: status ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        status ? Icons.check_circle : Icons.cancel,
                        color: status ? Colors.green : Colors.grey,
                        size: 22,
                      ),
                      Switch(
                        value: status,
                        onChanged: autoSystem
                            ? null
                            : (value) {
                                updateDatabase(thietBi, value);
                              },
                        activeColor: autoSystem ? Colors.grey : Colors.yellow,
                        inactiveThumbColor: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              if (!status) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Đã tắt được: ",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      timeElapsed,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    status ? "Sẽ tắt trong: " : "Sẽ bật trong: ",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    status ? timeRemaining : timeRemaining,
                    style: TextStyle(
                      fontSize: 15,
                      color: status ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    "Thời gian thực hiện: ",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _getNextChangeTime(schedule, status),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color:
                          status ? Colors.red.shade400 : Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
