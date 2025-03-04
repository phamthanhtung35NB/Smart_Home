import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';

class AquariumManager extends StatefulWidget {
  @override
  _AquariumManagerState createState() => _AquariumManagerState();
}

class _AquariumManagerState extends State<AquariumManager> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _bigLight = false;
  bool _waterPump = false;
  double _airPumpSpeed = 0.0;
  double _temperature = 0.0;
  String _currentTime = '';
  late StreamSubscription<DatabaseEvent> _temperatureSubscription;
  late StreamSubscription<DatabaseEvent> _bigLightSubscription;
  late StreamSubscription<DatabaseEvent> _waterPumpSubscription;
  late StreamSubscription<DatabaseEvent> _airPumpSpeedSubscription;
  late StreamSubscription<DatabaseEvent> _timeSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
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

    // Lắng nghe tốc độ bơm không khí
    _airPumpSpeedSubscription =
        _database.child('aquarium/airPumpSpeed').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _airPumpSpeed = (event.snapshot.value as num).toDouble();
        });
      }
    });
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

  @override
  void dispose() {
    _temperatureSubscription.cancel();
    _bigLightSubscription.cancel();
    _waterPumpSubscription.cancel();
    _airPumpSpeedSubscription.cancel();
    _timeSubscription.cancel();
    super.dispose();
  }

  void _updateDatabase(String key, dynamic value) {
    _database.child('aquarium/$key').set(value);
  }

  // void _syncDataFromFirebase() async {
  //   final bigLightSnapshot = await _database.child('aquarium/bigLight').once();
  //   if (bigLightSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _bigLight = bigLightSnapshot.snapshot.value as bool;
  //     });
  //   }
  //
  //   final waterPumpSnapshot =
  //   await _database.child('aquarium/waterPump').once();
  //   if (waterPumpSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _waterPump = waterPumpSnapshot.snapshot.value as bool;
  //     });
  //   }
  //
  //   final airPumpSpeedSnapshot =
  //   await _database.child('aquarium/airPumpSpeed').once();
  //   if (airPumpSpeedSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _airPumpSpeed = (airPumpSpeedSnapshot.snapshot.value as num).toDouble();
  //     });
  //   }
  //
  //   final temperatureSnapshot =
  //   await _database.child('aquarium/temperature').once();
  //   if (temperatureSnapshot.snapshot.value != null) {
  //     setState(() {
  //       _temperature = (temperatureSnapshot.snapshot.value as num).toDouble();
  //     });
  //   }
  // }

  // void _updateDatabase(String key, dynamic value) {
  //   _database.child('aquarium/$key').set(value);
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildSectionCardCurrent(
              'Nhiệt độ bể cá',
              Icon(Icons.thermostat, color: Theme.of(context).primaryColor),
              (() {
                if (_temperature >= 27) {
                  return Text(
                    '${_temperature.toStringAsFixed(3)} °C',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  );
                } else if (_temperature < 27 && _temperature > 23) {
                  return Text(
                    '${_temperature.toStringAsFixed(3)} °C',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  );
                } else {
                  return Text(
                    '${_temperature.toStringAsFixed(3)} °C',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  );
                }
              })(),
            ),
            buildSectionCard2(
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
            buildSectionCard2(
              'Bơm không khí',
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
            buildSectionCard(
              'Tốc độ bơm không khí',
              Icon(Icons.air, color: Theme.of(context).primaryColor),
              Column(
                children: [
                  Slider(
                    value: _airPumpSpeed,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _airPumpSpeed.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _airPumpSpeed = value;
                        _updateDatabase('airPumpSpeed', value.toInt());
                      });
                    },
                  ),
                  Text(
                    '${_airPumpSpeed.round()}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionCard(String title, Icon icon, Widget content) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  //
  Widget buildSectionCard2(String title, Widget leading, Widget trailing) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                leading,
                SizedBox(width: 10),
                Text(title,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Current Time: $_currentTime',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    leading,
                    SizedBox(width: 10),
                    Text(
                      title,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
