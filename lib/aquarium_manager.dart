import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';

import 'package:intl/intl.dart';

class AquariumManager extends StatefulWidget {
  @override
  _AquariumManagerState createState() => _AquariumManagerState();
}

class _AquariumManagerState extends State<AquariumManager> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  bool _bigLight = false;
  bool _waterPump = false;
  // double _airPumpSpeed = 0.0;
  double _temperature = 0.0;
  double _temperatureOld = 0.0;
  String _currentTime = '';
  late Timer _timer;
  late StreamSubscription<DatabaseEvent> _temperatureSubscription;
  late StreamSubscription<DatabaseEvent> _temperatureSubscriptionOld;
  late StreamSubscription<DatabaseEvent> _bigLightSubscription;
  late StreamSubscription<DatabaseEvent> _waterPumpSubscription;
  late StreamSubscription<DatabaseEvent> _airPumpSpeedSubscription;
  late StreamSubscription<DatabaseEvent> _timeSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _startTimer();
  }

  void _setupRealtimeListeners() {
    // Lắng nghe nhiệt độ
    _temperatureSubscription =
        _database.child('aquarium/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _temperature = (event.snapshot.value as num).toDouble();
        });
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

    // Lắng nghe đèn hồ cá
    _bigLightSubscription =
        _database.child('aquarium/bigLight').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _bigLight = event.snapshot.value as bool;
        });
      }
    });

    // Lắng nghe bơm nước
    _waterPumpSubscription =
        _database.child('aquarium/waterPump').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _waterPump = event.snapshot.value as bool;
        });
      }
    });

    // // Lắng nghe tốc độ bơm không khí
    // _airPumpSpeedSubscription =
    //     _database.child('aquarium/airPumpSpeed').onValue.listen((event) {
    //   if (event.snapshot.value != null) {
    //     setState(() {
    //       _airPumpSpeed = (event.snapshot.value as num).toDouble();
    //     });
    //   }
    // });

    // Lắng nghe thời gian
    _timeSubscription =
        _database.child('aquarium/time').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTime = event.snapshot.value as String;
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
    _temperatureSubscription.cancel();
    _bigLightSubscription.cancel();
    _waterPumpSubscription.cancel();
    // _airPumpSpeedSubscription.cancel();
    _timeSubscription.cancel();
    _temperatureSubscriptionOld.cancel();
    _timer.cancel();
    super.dispose();
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

  void _updateDatabase(String key, dynamic value) {
    _database.child('aquarium/$key').set(value);
    _database.child('status/$key').set(value);
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildSectionCardCurrent(
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
            buildSectionCard(
              'Đèn hồ cá',
              Icon(Icons.lightbulb,
                  color: _bigLight ? Colors.yellow : Colors.grey),
              Switch(
                value: _bigLight,
                onChanged: (value) {
                  setState(() {
                    _bigLight = value;
                    _updateDatabase('bigLight', value);
                  });
                },
              ),
            ),
            buildSectionCard(
              'Bơm Oxy',
              Icon(Icons.water_drop,
                  color: _waterPump ? Colors.blue : Colors.grey),
              Switch(
                value: _waterPump,
                onChanged: (value) {
                  setState(() {
                    _waterPump = value;
                    _updateDatabase('waterPump', value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionCard(String title, Widget leading, Widget trailing) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget buildSectionCardCurrent(
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
                  _getTimeElapsed(_currentTime),
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
                _currentTime,
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
}
