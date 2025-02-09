import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  int _currentEffect = 0;
  double _brightness = 200.0;
  double _speed = 50.0;
  Color _selectedColor = Colors.red;

  void _updateDatabase(String key, dynamic value) {
    _database.child(key).set(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LED Controller'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiệu ứng hiện tại
            Text('Effect:', style: TextStyle(fontSize: 18)),
            DropdownButton<int>(
              value: _currentEffect,
              items: List.generate(11, (index) => DropdownMenuItem(
                value: index,
                child: Text('Effect $index'),
              )),
              onChanged: (value) {
                setState(() {
                  _currentEffect = value!;
                  _updateDatabase('currentEffect', value);
                });
              },
            ),

            SizedBox(height: 20),

            // Độ sáng
            Text('Brightness:', style: TextStyle(fontSize: 18)),
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

            SizedBox(height: 20),

            // Tốc độ
            Text('Speed:', style: TextStyle(fontSize: 18)),
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

            SizedBox(height: 20),

            // Màu sắc
            Text('Color:', style: TextStyle(fontSize: 18)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Color? pickedColor = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Pick a color'),
                          content: SingleChildScrollView(
                            child: BlockPicker(
                              pickerColor: _selectedColor,
                              onColorChanged: (color) {
                                Navigator.of(context).pop(color);
                              },
                            ),
                          ),
                        ),
                      );
                      if (pickedColor != null) {
                        setState(() {
                          _selectedColor = pickedColor;
                          _updateDatabase('color', {
                            'r': pickedColor.red,
                            'g': pickedColor.green,
                            'b': pickedColor.blue,
                          });
                        });
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}