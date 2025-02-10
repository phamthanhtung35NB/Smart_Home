import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LampController extends StatefulWidget {
  @override
  _LampControllerState createState() => _LampControllerState();
}

class _LampControllerState extends State<LampController> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _lampStatus = false;
  bool _lampLevel = false;

  void _syncDataFromFirebase() async {
    final statusSnapshot = await _database.child('lamp/status').once();
    if (statusSnapshot.snapshot.value != null) {
      setState(() {
        _lampStatus = statusSnapshot.snapshot.value as bool;
      });
    }

    final levelSnapshot = await _database.child('lamp/level').once();
    if (levelSnapshot.snapshot.value != null) {
      setState(() {
        _lampLevel = statusSnapshot.snapshot.value as bool;
      });
    }
  }

  void _updateDatabase(String key, dynamic value) {
    _database.child('lamp/$key').set(value);
  }

  @override
  void initState() {
    super.initState();
    _syncDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Lamp Status',
              Icon(Icons.lightbulb, color: _lampStatus ? Colors.yellow : Colors.grey),
              Switch(
                value: _lampStatus,
                onChanged: (value) {
                  setState(() {
                    _lampStatus = value;
                    _updateDatabase('status', value);
                  });
                },
              ),
            ),
            _buildSectionCard(
              'Lamp Level',
              Icon(Icons.wb_sunny, color: Theme.of(context).primaryColor),
              Switch(
                value: _lampLevel,
                onChanged: (value) {
                  setState(() {
                    _lampLevel = value;
                    _updateDatabase('level', value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Icon icon, Widget content) {
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
}
