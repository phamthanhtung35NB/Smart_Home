// lib/screen/web_view_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:rgbs/widgets/buid/dht_humidity_card.dart';
import 'package:rgbs/widgets/buid/temperature_card.dart';

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // System status variables
  bool _autoSystem = false;
  bool _bigLight = false;
  bool _waterPump = false;
  bool _fan = false;
  bool _heater = false;
  String _warning = '';

  // Temperature data
  double _temperature = 0.0;
  double _temperatureOld = 0.0;
  String _currentTime = '--:--:--';
  String _currentTimeTemperature = '--:--:--';

  // DHT11 sensor data
  double _humidity = 0.0;
  double _dhtTemperatureC = 0.0;
  double _heatIndexC = 0.0;

  // Subscriptions
  late StreamSubscription _autoSystemSubscription;
  late StreamSubscription _bigLightSubscription;
  late StreamSubscription _waterPumpSubscription;
  late StreamSubscription _temperatureSubscription;
  late StreamSubscription _temperatureSubscriptionOld;
  late StreamSubscription _timeSubscription;
  late StreamSubscription _timeSubscriptionTemperature;
  late StreamSubscription _dhtSubscription;
  late StreamSubscription _fanSubscription;
  late StreamSubscription _heaterSubscription;
  late StreamSubscription _warningSubscription;

  // Timer for UI updates
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // Auto system subscription
    _autoSystemSubscription =
        _database.child('status/auto').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _autoSystem = event.snapshot.value as bool;
        });
      }
    });

    // Big light subscription
    _bigLightSubscription =
        _database.child('status/bigLight').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _bigLight = event.snapshot.value as bool;
        });
      }
    });

    // Water pump subscription
    _waterPumpSubscription =
        _database.child('status/waterPump').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _waterPump = event.snapshot.value as bool;
        });
      }
    });

    // Time subscription
    _timeSubscription =
        _database.child('aquarium/readtime').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTime = event.snapshot.value as String;
        });
      }
    });

    // Temperature subscription
    _temperatureSubscription =
        _database.child('aquarium/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _temperature = (event.snapshot.value as num).toDouble();
        });
      }
    });

    // Old temperature subscription
    _temperatureSubscriptionOld =
        _database.child('aquarium/temperatureOld').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _temperatureOld = (event.snapshot.value as num).toDouble();
        });
      }
    });

    // Temperature time subscription
    _timeSubscriptionTemperature =
        _database.child('aquarium/time').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentTimeTemperature = event.snapshot.value as String;
        });
      }
    });

    // DHT11 sensor subscription
    _dhtSubscription = _database.child('dht').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> dhtData = event.snapshot.value as Map;
        setState(() {
          _humidity = (dhtData['humidity'] as num?)?.toDouble() ?? 0.0;
          _dhtTemperatureC = (dhtData['temperatureC'] as num?)?.toDouble() ?? 0.0;
          _heatIndexC = (dhtData['heatIndexC'] as num?)?.toDouble() ?? 0.0;
        });
      }
    });

    // Fan subscription
    _fanSubscription = _database.child('status/fan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _fan = event.snapshot.value as bool;
        });
      }
    });

    // Heater subscription
    _heaterSubscription = _database.child('status/heater').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _heater = event.snapshot.value as bool;
        });
      }
    });

    // Warning subscription
    _warningSubscription = _database.child('status/warning').onValue.listen((event) {
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
    _timeSubscription.cancel();
    _timeSubscriptionTemperature.cancel();
    _dhtSubscription.cancel();
    _fanSubscription.cancel();
    _heaterSubscription.cancel();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto System Status Card
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      titleAlignment: ListTileTitleAlignment.center,
                      title: Column(
                        children: [
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
                                      _autoSystem ? "Đang kích hoạt " : "Đã tắt ",
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
                                ),
                              ),
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

              // DHT11 Card
              DHT11HumidityCard(
                humidity: _humidity,
                dhtTemperatureC: _dhtTemperatureC,
                heatIndexC: _heatIndexC,
              ),

              const SizedBox(height: 15),

              // Temperature Card
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
                padding: EdgeInsets.only(left: 10, right: 10, top: 15),
                child: Text(
                  'Trạng thái thiết bị hiện tại:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 8),

              // Device Status Cards
              _buildStatusCard('Đèn bể cá', Icons.lightbulb, _bigLight, '13:00 - 23:30'),
              _buildStatusCard('Bơm Oxi', Icons.water_drop, _waterPump,
                  '00:00 - 03:00, 04:00 - 11:00, 12:00 - 14:00, 17:00 - 20:00, 22:00 - 00:00'),

              const SizedBox(height: 30),

              _buildControlCard('Tản Nhiệt', Icons.air, _fan, 'Bật khi >= 27.2°C, Tắt khi <= 26.3°C'),
              _buildControlCard('Sưởi', Icons.fireplace, _heater, 'Bật khi <= 22°C, Tắt khi >= 24°C'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for device status cards
  Widget _buildStatusCard(String title, IconData icon, bool status, String schedule) {
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
                Row(
                  children: [
                    Icon(icon, color: status ? Colors.amber : Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
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
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "Lịch trình: $schedule",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for control cards
  Widget _buildControlCard(String title, IconData icon, bool status, String threshold) {
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
                Row(
                  children: [
                    Icon(icon, color: status ? Colors.red : Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
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
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "Ngưỡng: $threshold",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for temperature text
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

  // Helper method for time elapsed calculation
  String _getTimeElapsed(String lastUpdateTime) {
    try {
      DateTime now = DateTime.now();
      DateTime lastUpdate = DateFormat('HH:mm:ss').parse(lastUpdateTime);
      lastUpdate = DateTime(
          now.year, now.month, now.day, lastUpdate.hour, lastUpdate.minute);
      Duration difference = now.difference(lastUpdate);
      if (difference.inHours > 0) {
        return '${difference.inHours} giờ ${difference.inMinutes % 60} phút';
      } else {
        int seconds = difference.inSeconds % 60;
        return '${difference.inMinutes} phút $seconds giây';
      }
    } catch (e) {
      return 'Invalid time format';
    }
  }
}