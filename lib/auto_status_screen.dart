import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Add this import statement
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AutoStatusScreen extends StatefulWidget {
  @override
  _AutoStatusScreenState createState() => _AutoStatusScreenState();
}

class _AutoStatusScreenState extends State<AutoStatusScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  bool _bigLight = false;
  bool _waterPump = false;
  bool _autoSystem = true; // Add this line
  String _currentTime = '';

  double _temperature = 0.0;
  double _temperatureOld = 0.0;
  String _currentTimeTemperature = '';

  late Timer _timer;
  late StreamSubscription<DatabaseEvent> _temperatureSubscription;
  late StreamSubscription<DatabaseEvent> _temperatureSubscriptionOld;
  late StreamSubscription<DatabaseEvent> _timeSubscriptionTemperature;

  late StreamSubscription<DatabaseEvent> _autoSystemSubscription;
  late StreamSubscription<DatabaseEvent> _bigLightSubscription;
  late StreamSubscription<DatabaseEvent> _waterPumpSubscription;
  late StreamSubscription<DatabaseEvent> _timeSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _startTimer();_initializeNotifications();
  }
  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  Future<void> _sendPushNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Cảnh báo nhiệt độ',
      'Nhiệt độ vượt ngưỡng cho phép!',
      platformChannelSpecifics,
    );
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
    _timeSubscription = _database.child('aquarium/readtime').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTime = event.snapshot.value as String;
        });
      }
    });
    // Lắng nghe nhiệt độ
    _temperatureSubscription = _database.child('aquarium/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _temperature = (event.snapshot.value as num).toDouble();
        });
        if (_temperature >= 26||_temperature<=23) {
          _sendPushNotification();
        }
      }
    });

    // Lắng nghe nhiệt độ cũ
    _temperatureSubscriptionOld =
        _database.child('aquarium/temperatureOld').onValue.listen((event) {
          if (event.snapshot.value != null) {
            setState(() {
              _temperatureOld = (event.snapshot.value as num).toDouble();
            });
          }
        });
    // Lắng nghe thời gian
    _timeSubscriptionTemperature =
        _database.child('aquarium/time').onValue.listen((event) {
          if (event.snapshot.value != null) {
            setState(() {
              _currentTimeTemperature = event.snapshot.value as String;
            });
          }
        });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }
  @override
  void dispose() {
    _autoSystemSubscription.cancel();
    _bigLightSubscription.cancel();
    _waterPumpSubscription.cancel();
    // _timeSubscription.cancel();
    _temperatureSubscription.cancel();
    _temperatureSubscriptionOld.cancel();
    _timeSubscriptionTemperature.cancel();
    _timer.cancel();
    // super.dispose();
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
                    // Thay thế ListTile hiện tại bằng đoạn code sau
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      titleAlignment: ListTileTitleAlignment.center,
                      title: Column(
                        children: [
                          const SizedBox(height: 10),
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
                              duration: const Duration(milliseconds: 300),
                              width: 280,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(39),
                                color: _autoSystem
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                              // vị trí của thanh trượt
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    left: _autoSystem ? 200 : 0,
                                    top: 0,
                                    bottom: 0,
                                    right: _autoSystem ? 0 : 200,
                                    // thanh trượt
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      // màu của thanh trượt
                                      //
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 29,
                                            offset: Offset(0, 6),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      _autoSystem ? 'ON' : 'OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                  width: 200,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _autoSystem
                                        ? Colors.green.shade100
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [

                                      Text(
                                        _autoSystem
                                            ? "Đang kích hoạt "
                                            : "Đã tắt ",
                                        style: TextStyle(
                                          color: _autoSystem
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        _autoSystem
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _autoSystem
                                            ? Colors.green
                                            : Colors.grey,
                                        size: 30,
                                      ),
                                    ],
                                  )),
                            ],
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
              temperatureCardConstruction(
                'Nhiệt độ bể cá',
                Icon(Icons.thermostat, color: Theme.of(context).primaryColor),
                (() {
                  if (_temperature >= 26) {
                    return Text(
                      '${_temperature.toStringAsFixed(3)} °C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    );
                  } else if (_temperature < 26 && _temperature > 23) {
                    return Text(
                      '${_temperature.toStringAsFixed(3)} °C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    );
                  } else {
                    return Text(
                      '${_temperature.toStringAsFixed(3)} °C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    );
                  }
                })(),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  'Trạng thái thiết bị hiện tại:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusCard('Đèn bể cá','bigLight', _bigLight, '13:00 - 23:30'),
              //  '4:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 3:00',
              _buildStatusCard('Bơm Oxi', 'waterPump', _waterPump,
                  '00:00 - 03:00, 04:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 00:00'),
              const SizedBox(height: 20),
              const Text(
                'Lịch trình hoạt động:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildScheduleCard('Đèn bể cá', '13:00 - 23:30'),
              //  '4:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 3:00',
              _buildScheduleCard('Bơm Oxi',
                  '00:00 - 03:00, 04:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 00:00'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  void _updateDatabase(String key, dynamic value) {
    // _database.child('aquarium/$key').set(value);
    _database.child('status/$key').set(value);
  }
  Widget _buildStatusCard(String title,String thietBi, bool status, String schedule) {
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
                    if (thietBi == 'bigLight') ...[
                      Switch(
                        value: _bigLight,
                        onChanged: _autoSystem ? null : (value) {
                          setState(() {
                            _bigLight = value;
                            _updateDatabase(thietBi, value);
                          });
                        },
                        activeColor: _autoSystem ? Colors.grey : Colors.yellow,
                        inactiveThumbColor: Colors.grey,
                      ),
                    ] else ...[
                      Switch(
                        value: _waterPump,
                        onChanged: _autoSystem ? null : (value) {
                          setState(() {
                            _waterPump = value;
                            _updateDatabase(thietBi, value);
                          });
                        },
                        activeColor: _autoSystem ? Colors.grey : Colors.blue,
                        inactiveThumbColor: Colors.grey,
                      ),
                    ],
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Text(
            //   "Lịch trình:",
            //   style: TextStyle(
            //     fontSize: 15,
            //     color: Colors.grey.shade700,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            const SizedBox(height: 4),
            Wrap(
              // căn giữa các chip
              alignment: WrapAlignment.center,

              // Khoảng cách giữa các chip
              spacing: 15,
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
                        Colors.green.shade100; //Khoảng thời gian hoạt động
                  } else if (isPast) {
                    backgroundColor = Colors.yellow.shade400; // past time slot
                  }
                }

                return Chip(
                  backgroundColor: backgroundColor,
                  side: BorderSide.none,
                  label: Text(
                    time,
                    style: TextStyle(
                      fontSize: 15,
                      color: isActive
                          ? Colors.green.shade900
                          : Colors.blue.shade900,
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

  Widget temperatureCardConstruction(
      String title, Widget leading, Widget trailing) {
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
                    leading,
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Cập nhật nhiệt độ gần nhất: ',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  _getTimeElapsed(_currentTimeTemperature),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text(
                'Lúc: ',
                style: TextStyle(
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                _currentTimeTemperature,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ]),
            const Divider(
              color: Colors.grey,
              thickness: 1, //đây là thông số độ dày
              indent: 5, //đây là thông số khoảng cách bên trái
              endIndent: 5, //đây là thông số khoảng cách bên phải
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Nhiệt độ trước đó: ',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '${_temperatureOld.toStringAsFixed(3)} °C',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  String _getTimeElapsed(String lastUpdateTime) {
    try {
      DateTime now = DateTime.now();
      DateTime lastUpdate = DateFormat('HH:mm:ss').parse(lastUpdateTime);
      // Adjust the lastUpdate to today's date
      lastUpdate = DateTime(
          now.year, now.month, now.day, lastUpdate.hour, lastUpdate.minute);
      Duration difference = now.difference(lastUpdate);
      if (difference.inHours > 0) {
        return '${difference.inHours} giờ ${difference.inMinutes % 60} phút';
      } else {
        int seconds = difference.inSeconds % 60;
        //bỏ qua số sau dấu phẩy
        return '${difference.inMinutes} phút $seconds giây';
      }
    } catch (e) {
      // Handle the exception by returning a default value or logging the error
      return 'Invalid time format';
    }
  }
}
