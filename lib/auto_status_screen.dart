import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Add this import statement
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AutoStatusScreen extends StatefulWidget {
  @override
  _AutoStatusScreenState createState() => _AutoStatusScreenState();
}

class _AutoStatusScreenState extends State<AutoStatusScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _bigLight = false;
  bool _waterPump = false;
  bool _autoSystem = true; // Add this line
  String _currentTime = '';

  late StreamSubscription<DatabaseEvent> _autoSystemSubscription;
  late StreamSubscription<DatabaseEvent> _bigLightSubscription;
  late StreamSubscription<DatabaseEvent> _waterPumpSubscription;
  late StreamSubscription<DatabaseEvent> _timeSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Lắng nghe hệ thống tự động
    _autoSystemSubscription =
        _database.child('status/auto').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _autoSystem = event.snapshot.value as bool;
        });
      }
    });

    // Lắng nghe đèn lớn
    _bigLightSubscription =
        _database.child('status/bigLight').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _bigLight = event.snapshot.value as bool;
        });
      }
    });

    // Lắng nghe bơm nước
    _waterPumpSubscription =
        _database.child('status/waterPump').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _waterPump = event.snapshot.value as bool;
        });
      }
    });

    // Lắng nghe thời gian
    _timeSubscription = _database.child('status/time').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTime = event.snapshot.value as String;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoSystemSubscription.cancel();
    _bigLightSubscription.cancel();
    _waterPumpSubscription.cancel();
    _timeSubscription.cancel();
    super.dispose();
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _syncDataFromFirebase();
  // }
  //
  // void _syncDataFromFirebase() async {
  //   // Add auto system status
  //   final autoSystemSnapshot = await _database.child('status/auto').once();
  //   if (autoSystemSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _autoSystem = autoSystemSnapshot.snapshot.value as bool;
  //     });
  //   }
  //
  //   // Existing code...
  //   final bigLightSnapshot = await _database.child('status/bigLight').once();
  //   if (bigLightSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _bigLight = bigLightSnapshot.snapshot.value as bool;
  //     });
  //   }
  //
  //   final waterPumpSnapshot = await _database.child('status/waterPump').once();
  //   if (waterPumpSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _waterPump = waterPumpSnapshot.snapshot.value as bool;
  //     });
  //   }
  //
  //   final timeSnapshot = await _database.child('status/time').once();
  //   if (timeSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _currentTime = timeSnapshot.snapshot.value as String;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromRGBO(33, 150, 243, 1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.only(top: 30, left: 10, right: 10),
        child: SingleChildScrollView(
          // Add this widget
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add auto system switch
              Card(
                child: Column(
                  // căn giữa các phần tử
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      color: _autoSystem ? Colors.green.shade50 : Colors.grey,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _autoSystem ? Icons.check_circle : Icons.cancel,
                            color: _autoSystem ? Colors.green : Colors.grey,
                            size: 32,
                          ),
                        ],
                      ),
                    ),
                    // Thay thế ListTile hiện tại bằng đoạn code sau
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      titleAlignment: ListTileTitleAlignment.center,
                      title: Column(
                        children: [
                          Text(
                            'Chế độ tự động theo lịch trình',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onHorizontalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity > 0) {
                                // Vuốt sang phải
                                setState(() {
                                  _autoSystem = true;
                                  _database.child('status/auto').set(true);
                                });
                              } else if (velocity < 0) {
                                // Vuốt sang trái
                                setState(() {
                                  _autoSystem = false;
                                  _database.child('status/auto').set(false);
                                });
                              }
                            },
                            child: AnimatedContainer(
                              alignment: Alignment.center,
                              duration: Duration(milliseconds: 300),
                              width: 120,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: _autoSystem ? Colors.green : Colors.grey.shade400,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: 300),
                                    left: _autoSystem ? 40 : 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 100,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      _autoSystem ? 'ON' : 'OFF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: null, // Bỏ trailing để tránh lệch sang phải
                    ),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              const Text(
                                'Thời gian cập nhật gần nhất:',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 3),
                              // Add some space between the texts
                              Text(
                                _currentTime,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  'Trạng thái thiết bị hiện tại:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusCard('Đèn bể cá', _bigLight, '13:00 - 23:30'),
              _buildStatusCard('Bơm Oxi', _waterPump,
                  '00:00 - 02:30, 04:30 - 09:00, 10:00 - 13:00, 14:00 - 17:00, 18:00 - 21:00, 22:00 - 00:00'),
              const SizedBox(height: 20),
              const Text(
                'Lịch trình hoạt động:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildScheduleCard('Đèn bể cá', '13:00 - 23:30'),
              _buildScheduleCard('Bơm Oxi',
                  '00:00 - 02:30, 04:30 - 09:00, 10:00 - 13:00, 14:00 - 17:00, 18:00 - 21:00, 22:00 - 00:00'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, bool status, String schedule) {
    String timeElapsed = '';
    String timeRemaining = '';

    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    if (status) {
      // Function is currently on, calculate time until it turns off
      timeRemaining =
          _getTimeUntilNextEvent(schedule, currentTimeInMinutes, true);
    } else {
      // Function is currently off, calculate time since it turned off and time until it turns on
      timeElapsed = _getTimeSinceLastEvent(schedule, currentTimeInMinutes);
      timeRemaining =
          _getTimeUntilNextEvent(schedule, currentTimeInMinutes, false);
    }

    return Card(
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
                      fontSize: 16,
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
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      status ? 'Bật' : 'Tắt',
                      style: TextStyle(
                        fontSize: 14,
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
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    timeElapsed,
                    style: TextStyle(
                      fontSize: 14,
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
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status ? timeRemaining : timeRemaining,
                  style: TextStyle(
                    fontSize: 14,
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
                  "Thời gian hoạt đông trở lại:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getNextChangeTime(schedule, status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: status ? Colors.red.shade400 : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  // Hàm này sẽ trả về thời gian kể từ sự kiện cuối cùng
  String _getTimeSinceLastEvent(String schedule, int currentTimeInMinutes) {
    final times = schedule.split(', ').map((time) {
      final parts = time.split(' - ');
      return _convertTimeToMinutes(parts[1]);
    }).toList();

    times.sort();
    for (final time in times.reversed) {
      if (currentTimeInMinutes >= time) {
        final difference = currentTimeInMinutes - time;
        return '${difference ~/ 60} Giờ ${difference % 60} Phút';
      }
    }
    return '0 Phút';
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

// String _getTimeElapsed(String lastUpdateTime) {
//   try {
//     DateTime now = DateTime.now();
//     DateTime lastUpdate = DateFormat('HH:mm:ss').parse(lastUpdateTime);
//     lastUpdate = DateTime(now.year, now.month, now.day, lastUpdate.hour, lastUpdate.minute);
//     Duration difference = now.difference(lastUpdate);
//     if (difference.inHours > 0) {
//       return '${difference.inHours} hours ${difference.inMinutes % 60} minutes';
//     } else {
//       int seconds = difference.inSeconds % 60;
//       return '${difference.inMinutes} minutes $seconds seconds';
//     }
//   } catch (e) {
//     return 'Invalid time format';
//   }
// }
//
// String _getTimeRemaining(String nextUpdateTime) {
//   try {
//     DateTime now = DateTime.now();
//     DateTime nextUpdate = DateFormat('HH:mm:ss').parse(nextUpdateTime);
//     nextUpdate = DateTime(now.year, now.month, now.day, nextUpdate.hour, nextUpdate.minute);
//     Duration difference = nextUpdate.difference(now);
//     if (difference.isNegative) {
//       difference = difference + Duration(days: 1);
//     }
//     if (difference.inHours > 0) {
//       return '${difference.inHours} hours ${difference.inMinutes % 60} minutes';
//     } else {
//       int seconds = difference.inSeconds % 60;
//       return '${difference.inMinutes} minutes $seconds seconds';
//     }
//   } catch (e) {
//     return 'Invalid time format';
//   }
// }

  Widget _buildScheduleCard(String title, String schedule) {
    // Get current time in minutes for comparison
    final now = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    return Card(
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
              children: [
                Icon(
                  title.contains("Đèn") ? Icons.lightbulb : Icons.water,
                  color: Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Text(
            //   "Lịch trình:",
            //   style: TextStyle(
            //     fontSize: 14,
            //     color: Colors.grey.shade700,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            const SizedBox(height: 4),
            Wrap(
              // căn giữa các chip
              alignment: WrapAlignment.center,

              spacing: 6,
              children: schedule.split(', ').map((time) {
                // Phân tích cú pháp phạm vi thời gian và xác định xem nó đang hoạt động hay quá khứ
                bool isActive = false;
                bool isPast = false;

                if (_autoSystem) {
                  final times = time.split(' - ');
                  // Đảm bảo rằng có đúng 2 thời gian trong phạm vi
                  if (times.length == 2) {
                    // Chuyển đổi thời gian thành phút
                    final startTime = _convertTimeToMinutes(times[0]);
                    // Chuyển đổi thời gian thành phút
                    final endTime = _convertTimeToMinutes(times[1]);

                    // Kiểm tra xem thời gian hiện tại có nằm trong phạm vi này hay không
                    if (startTime < endTime) {
                      // Phạm vi thời gian bình thường trong cùng một ngày
                      isActive = currentTimeInMinutes >= startTime &&
                          currentTimeInMinutes < endTime;
                      isPast = currentTimeInMinutes >= endTime;
                    }
                    // else {
                    //   // Phạm vi thời gian kéo dài đến nửa đêm
                    //   isActive = currentTimeInMinutes >= startTime || currentTimeInMinutes < endTime;
                    //   isPast = currentTimeInMinutes >= endTime && currentTimeInMinutes < startTime;
                    // }
                  }
                }

                // Đặt màu nền thích hợp dựa trên trạng thái
                Color backgroundColor = Colors.blue.shade50; // Mặc định
                if (_autoSystem) {
                  if (isActive) {
                    backgroundColor =
                        Colors.green.shade200; //Khoảng thời gian hoạt động
                  } else if (isPast) {
                    backgroundColor = Colors.yellow.shade100; // past time slot
                  }
                }

                return Chip(
                  backgroundColor: backgroundColor,
                  side: BorderSide.none,
                  label: Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive
                          ? Colors.green.shade800
                          : Colors.blue.shade800,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

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
}
