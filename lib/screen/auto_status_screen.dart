import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Add this import statement
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rgbs/widgets/buid/status_card.dart';
import 'package:rgbs/widgets/buid/gesture_switch.dart';
import 'package:rgbs/widgets/buid/dht_humidity_card.dart';
import 'package:rgbs/widgets/buid/temperature_card.dart';
import 'package:rgbs/widgets/buid/status_card2.dart';
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
  bool _fan = false;
  bool _heater = false;

  String _currentTime = '';

  double _temperature = 0.0;
  double _temperatureOld = 0.0;
  String _currentTimeTemperature = '';

  // DHT11 sensor data
  double _humidity = 0.0;
  double _dhtTemperatureC = 0.0;
  double _dhtTemperatureF = 0.0;
  double _heatIndexC = 0.0;
  double _heatIndexF = 0.0;
  String _warning = '';
  late StreamSubscription<DatabaseEvent> _dhtSubscription;

  late Timer _timer;
  late StreamSubscription<DatabaseEvent> _temperatureSubscription;
  late StreamSubscription<DatabaseEvent> _temperatureSubscriptionOld;
  late StreamSubscription<DatabaseEvent> _timeSubscriptionTemperature;

  late StreamSubscription<DatabaseEvent> _autoSystemSubscription;
  late StreamSubscription<DatabaseEvent> _bigLightSubscription;
  late StreamSubscription<DatabaseEvent> _waterPumpSubscription;
  late StreamSubscription<DatabaseEvent> _timeSubscription;
  late StreamSubscription<DatabaseEvent> _fanSubscription;
  late StreamSubscription<DatabaseEvent> _heaterSubscription;
  late StreamSubscription<DatabaseEvent> _warningSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _startTimer();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _sendPushNotification(double t) async {
    // Cấu hình chi tiết thông báo cho Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // ID của kênh thông báo
      'your_channel_name', // Tên của kênh thông báo
      channelDescription: 'your_channel_description', // Mô tả của kênh thông báo
      importance: Importance.max, // Mức độ quan trọng của thông báo (cao nhất)
      priority: Priority.high, // Độ ưu tiên của thông báo (cao)
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Âm thanh thông báo
    );

    // Cấu hình chi tiết thông báo chung cho các nền tảng
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Hiển thị thông báo đẩy
    await flutterLocalNotificationsPlugin.show(
      0, // ID của thông báo
      'Cảnh báo nhiệt độ', // Tiêu đề của thông báo
      'Nhiệt độ hiện tại: $t \nĐã vượt ngưỡng an toàn!', // Nội dung của thông báo
      platformChannelSpecifics, // Chi tiết cấu hình thông báo
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
    _timeSubscription =
        _database.child('aquarium/readtime').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTime = event.snapshot.value as String;
        });
      }
    });
    // Lắng nghe nhiệt độ
    _temperatureSubscription =
        _database.child('aquarium/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _temperature = (event.snapshot.value as num).toDouble();
        });
        if (_temperature <=22 || _temperature >= 26.5) {
          _sendPushNotification(_temperature);
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
    // Lắng nghe cảm biến DHT11
    _dhtSubscription = _database.child('dht').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> dhtData = event.snapshot.value as Map;
        setState(() {
          _humidity = (dhtData['humidity'] as num?)?.toDouble() ?? 0.0;
          _dhtTemperatureC =
              (dhtData['temperatureC'] as num?)?.toDouble() ?? 0.0;
          _dhtTemperatureF =
              (dhtData['temperatureF'] as num?)?.toDouble() ?? 0.0;
          _heatIndexC = (dhtData['heatIndexC'] as num?)?.toDouble() ?? 0.0;
          _heatIndexF = (dhtData['heatIndexF'] as num?)?.toDouble() ?? 0.0;
        });
      }
    });
    _fanSubscription = _database.child('status/fan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _fan = event.snapshot.value as bool;
        });
      }
    });

    _heaterSubscription =
        _database.child('status/heater').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _heater = event.snapshot.value as bool;
        });
      }
    });
    _warningSubscription =
        _database.child('status/warning').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _warning = event.snapshot.value as String;
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
    _temperatureSubscription.cancel();
    _temperatureSubscriptionOld.cancel();
    _timeSubscriptionTemperature.cancel();
    _fanSubscription.cancel();
    _heaterSubscription.cancel();
    _dhtSubscription.cancel(); // Add this line
    _warningSubscription.cancel();
    _timer.cancel();
    super.dispose();
  }

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
                          GestureSwitch(
                            autoSystem: _autoSystem,
                            onChanged: (value) {
                              setState(() {
                                _autoSystem = value;
                                _database.child('status/auto').set(value);
                              });
                            },
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
                      trailing: null,
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
              // Add DHT11 humidity card
              DHT11HumidityCard(
                humidity: _humidity,
                dhtTemperatureC: _dhtTemperatureC,
                heatIndexC: _heatIndexC,
              ),
              const SizedBox(height: 15),
              TemperatureCard(
                title: 'Nhiệt độ bể cá',
                warning: _warning,
                leading: Icon(Icons.thermostat,
                    color: Theme.of(context).primaryColor),
                trailing: _buildTemperatureText(_temperature),
                currentTimeTemperature: _currentTimeTemperature,
                temperatureOld: _temperatureOld.toStringAsFixed(3),
                getTimeElapsed: _getTimeElapsed,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Text(
                  'Trạng thái thiết bị hiện tại:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              StatusCard(
                title: 'Đèn bể cá',
                thietBi: 'bigLight',
                status: _bigLight,
                autoSystem: _autoSystem,
                updateDatabase: _updateDatabase,
                schedule: '13:00 - 23:30',
                onTap: () {
                  _showScheduleDialog(context, 'Đèn bể cá', '13:00 - 23:30');
                },
              ),
              //  '4:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 3:00',
              StatusCard(
                title: 'Bơm Oxi',
                thietBi: 'waterPump',
                status: _waterPump,
                autoSystem: _autoSystem,
                updateDatabase: _updateDatabase,
                schedule:
                    '00:00 - 03:00, 04:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 00:00',
                onTap: () {
                  _showScheduleDialog(context, 'Bơm Oxi',
                      '00:00 - 03:00, 04:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 00:00');
                },
              ),
              const SizedBox(height: 30),
              StatusCard2(
                title: "Quạt",
                thietBi: "fan",
                status: _fan,
                updateDatabase: _updateDatabase,
              ),
              StatusCard2(
                title: "Sưởi",
                thietBi: "heater",
                status: _heater,
                updateDatabase: _updateDatabase,
              ),
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

  Widget _buildTemperatureText(double temperature) {
    Color textColor;
    if (temperature >= 26.5) {
      textColor = Colors.redAccent;
    } else if (temperature <= 25.5 && temperature >= 23) {
      textColor = Colors.greenAccent;
    } else if (temperature <= 23) {
      textColor = Colors.blueGrey;
    } else {
      textColor = Colors.blueAccent;
    }

    return Text(
      '${temperature.toStringAsFixed(3)} °C',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  void _showScheduleDialog(
      BuildContext context, String title, String schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: _buildScheduleCard(title, schedule),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

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
