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

    @override
    void initState() {
      super.initState();
      _syncDataFromFirebase();
    }

    void _syncDataFromFirebase() async {
      // Add auto system status
      final autoSystemSnapshot = await _database.child('status/auto').once();
      if (autoSystemSnapshot.snapshot.value != null) {
        setState(() {
          _autoSystem = autoSystemSnapshot.snapshot.value as bool;
        });
      }

      // Existing code...
      final bigLightSnapshot = await _database.child('status/bigLight').once();
      if (bigLightSnapshot.snapshot.value != null) {
        setState(() {
          _bigLight = bigLightSnapshot.snapshot.value as bool;
        });
      }

      final waterPumpSnapshot = await _database.child('status/waterPump').once();
      if (waterPumpSnapshot.snapshot.value != null) {
        setState(() {
          _waterPump = waterPumpSnapshot.snapshot.value as bool;
        });
      }

      final timeSnapshot = await _database.child('status/time').once();
      if (timeSnapshot.snapshot.value != null) {
        setState(() {
          _currentTime = timeSnapshot.snapshot.value as String;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Auto Status'),
        ),
        body:Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ Colors.white,Color.fromRGBO(33, 150, 243, 1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add auto system switch
              Card(
                child: ListTile(
                  title: Text('Auto System'),
                  trailing: Switch(
                    value: _autoSystem,
                    onChanged: (value) {
                      setState(() {
                        _autoSystem = value;
                        _database.child('status/auto').set(value);
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Current Time: $_currentTime',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildStatusCard('Big Light', _bigLight),
              _buildStatusCard('Water Pump', _waterPump),
              SizedBox(height: 20),
              Text(
                'Auto Schedule:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildScheduleCard('Big Light', '9:00 - 20:00'),
              _buildScheduleCard('Water Pump', '4:30 - 8:00, 9:00 - 12:00, 13:00 - 16:00, 17:00 - 20:00, 21:00 - 23:59'),
            ],
          ),
        ),
      );
    }


  Widget _buildStatusCard(String title, bool status) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          status ? Icons.check_circle : Icons.cancel,
          color: status ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(String title, String schedule) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(schedule),
      ),
    );
  }
}