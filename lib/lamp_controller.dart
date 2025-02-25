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
              'Đèn bàn',
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
              'Tăng cường ánh sáng',
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
  Widget _buildSectionCard(String title, Widget leading, Widget trailing) {
    return Card(
      color: Colors.white, // Đặt nền trắng
      elevation: 4, // Tạo hiệu ứng đổ bóng nhẹ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bo góc đẹp hơn
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
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing,
          ],
        ),
      ),
    );
  }


}