import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LedController extends StatefulWidget {
  @override
  _LedControllerState createState() => _LedControllerState();
}

class _LedControllerState extends State<LedController> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  int _currentEffect = 0;
  double _brightness = 200.0;
  double _speed = 50.0;
  Color _selectedColor = Colors.red;

  final List<String> effectNames = [
    'Tắt đèn',
    'Cầu vồng',
    'Nhịp đập ngẫu nhiên',
    'Nhịp đập theo màu',
    'Nước chảy',
    'Mưa rơi',
    'Nhấp nháy ngẫu nhiên',
    'Lấp lánh theo màu',
    'Đuổi màu',
  ];

  void _updateDatabase(String key, dynamic value) {
    _database.child('led/$key').set(value);
  }

  void _syncDataFromFirebase() async {
    final effectSnapshot = await _database.child('led/currentEffect').once();
    if (effectSnapshot.snapshot.value != null) {
      setState(() {
        _currentEffect = effectSnapshot.snapshot.value as int;
      });
    }

    final brightnessSnapshot = await _database.child('led/brightness').once();
    if (brightnessSnapshot.snapshot.value != null) {
      setState(() {
        _brightness = (brightnessSnapshot.snapshot.value as num).toDouble();
      });
    }

    final speedSnapshot = await _database.child('led/speed').once();
    if (speedSnapshot.snapshot.value != null) {
      setState(() {
        _speed = (speedSnapshot.snapshot.value as num).toDouble();
      });
    }

    final colorSnapshot = await _database.child('led/color').once();
    if (colorSnapshot.snapshot.value != null) {
      final Map<dynamic, dynamic> colorMap =
      colorSnapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _selectedColor = Color.fromRGBO(
          colorMap['r'] ?? 255,
          colorMap['g'] ?? 0,
          colorMap['b'] ?? 0,
          1.0,
        );
      });
    }
  }
  @override
  void initState() {
    super.initState();
    _syncDataFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
        // title: Text(
        //   'LED Controller',
        //   style: TextStyle(fontWeight: FontWeight.bold),
        // ),
        // elevation: 0,
        // centerTitle: true,
        // backgroundColor: Theme.of(context).primaryColor,
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  'Hiệu ứng',
                  Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _currentEffect,
                        items: List.generate(
                          effectNames.length,
                              (index) => DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              effectNames[index],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _currentEffect = value!;
                            _updateDatabase('currentEffect', value);
                          });
                        },
                      ),
                    ),
                  ),
                ),
                _buildSectionCard(
                  'Độ sáng',
                  Icon(Icons.brightness_6, color: Theme.of(context).primaryColor),
                  Column(
                    children: [
                      Slider(
                        value: _brightness,
                        min: 0,
                        max: 255,
                        divisions: 255,
                        label: _brightness.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _brightness = value;
                            _updateDatabase('brightness', value.toInt());
                          });
                        },
                      ),
                      Text(
                        '${_brightness.round()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSectionCard(
                  'Tốc độ',
                  Icon(Icons.speed, color: Theme.of(context).primaryColor),
                  Column(
                    children: [
                      Slider(
                        value: _speed,
                        min: 10,
                        max: 100,
                        divisions: 90,
                        label: _speed.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _speed = value;
                            _updateDatabase('speed', value.toInt());
                          });
                        },
                      ),
                      Text(
                        '${_speed.round()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSectionCard2(
                  'Màu sắc',
                  Icon(Icons.color_lens, color: Theme.of(context).primaryColor),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showColorPicker(context),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // SizedBox(height: 8),
                        // Text(
                        //   'Nhấn để chọn màu',
                        //   style: TextStyle(
                        //     fontSize: 14,
                        //     color: Colors.grey.shade600,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
  Widget _buildSectionCard2(String title, Widget leading, Widget trailing) {
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



  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chọn màu'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                  _updateDatabase('color', {
                    'r': color.red,
                    'g': color.green,
                    'b': color.blue,
                  });
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
}