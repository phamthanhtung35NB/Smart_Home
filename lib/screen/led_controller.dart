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
    'Sáng đơn màu', // Single color effect
    'Sáng màu ngẫu nhiên', // Random colors effect
    'Sáng màu ngẫu nhiên mượt', // Smooth random colors effect
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

  Widget _getEffectColorIndicator(int index) {
    if (index == 1 ||
        index == 2 ||
        index == 4 ||
        index == 5 ||
        index == 6 ||
        index == 10 ||
        index == 11) {
      return Container(
        width: 18, // Giảm kích thước nhẹ
        height: 18, // Giảm kích thước nhẹ
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple
            ],
            stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
      );
    }

    return Container(
      width: 18, // Giảm kích thước nhẹ
      height: 18, // Giảm kích thước nhẹ
      decoration: BoxDecoration(
        color: _getEffectColor(index),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _syncDataFromFirebase();
  }

  Color _getEffectColor(int effectIndex) {
    switch (effectIndex) {
      case 0:
        return Colors.grey; // Tắt đèn
      case 1:
        return Colors.lightBlue; // Cầu vồng
      case 2:
        return Colors.lightBlue; // Nhịp đập ngẫu nhiên
      case 3:
        return _selectedColor; // Nhịp đập theo màu
      case 4:
        return Colors.blue; // Nước chảy
      case 5:
        return Colors.lightBlue; // Mưa rơi
      case 6:
        return Colors.lightBlue; // Nhấp nháy ngẫu nhiên
      case 7:
        return _selectedColor; // Lấp lánh theo màu
      case 8:
        return _selectedColor; // Đuổi màu
      case 9:
        return _selectedColor; // Sáng đơn màu
      case 10:
        return Colors.lightBlue; // Sáng màu ngẫu nhiên
      case 11:
        return Colors.lightBlue; // Sáng màu ngẫu nhiên mượt
      default:
        return Colors.grey;
    }
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
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  'Điều chỉnh',
                  Icon(Icons.tune, color: Theme.of(context).primaryColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột bên trái (Độ sáng và Tốc độ)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phần Độ sáng
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.brightness_6,
                                          color: Theme.of(context).primaryColor,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Độ sáng',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    value: _brightness,
                                    min: 0,
                                    max: 255,
                                    divisions: 255,
                                    label: _brightness.round().toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _brightness = value;
                                        _updateDatabase(
                                            'brightness', value.toInt());
                                      });
                                    },
                                  ),
                                  Center(
                                    child: Text(
                                      '${_brightness.round()}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Phần Tốc độ
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.speed,
                                          color: Theme.of(context).primaryColor,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Tốc độ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Slider(
                                    value: _speed,
                                    min: 1,
                                    max: 200,
                                    divisions: 90,
                                    label: _speed.round().toString(),
                                    onChanged: (value) {
                                      setState(() {
                                        _speed = value;
                                        _updateDatabase('speed', value.toInt());
                                      });
                                    },
                                  ),
                                  Center(
                                    child: Text(
                                      '${_speed.round()}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Đường phân cách
                        Container(
                          height: 150,
                          width: 1,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                        ),
                        // Cột bên phải (Màu sắc)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.color_lens,
                                      color: Theme.of(context).primaryColor,
                                      size: 20),
                                  const SizedBox(width: 4),
                                  const Text('Màu sắc',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 25),
                              GestureDetector(
                                onTap: () => _showColorPicker(context),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 2),
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
                              const SizedBox(height: 25),
                              Text(
                                'Nhấn để chọn màu',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSectionCard(
                  'Hiệu ứng',
                  Icon(Icons.auto_awesome,
                      color: Theme.of(context).primaryColor),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 4,
                        // Giảm tỷ lệ chiều rộng/chiều cao để có thêm không gian cho text
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: effectNames.length,
                      itemBuilder: (context, index) {
                        bool isSelected = index == _currentEffect;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentEffect = index;
                              _updateDatabase('currentEffect', index);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              color: isSelected
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1)
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              // Thay đổi từ center sang start để căn lề trái
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  // Thêm padding bên trái
                                  child: _getEffectColorIndicator(index),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  // Thay Flexible bằng Expanded để sử dụng hết không gian còn lại
                                  child: Text(
                                    effectNames[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.black87,
                                    ),
                                    softWrap: true, // Cho phép xuống dòng
                                    maxLines: 2, // Giới hạn tối đa 2 dòng
                                    overflow: TextOverflow
                                        .ellipsis, // Vẫn giữ ellipsis nếu vượt quá 2 dòng
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionCard(String title, Icon icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildSectionCard2(String title, Widget leading, Widget trailing) {
    return Card(
      color: Colors.white,
      // Đặt nền trắng
      elevation: 4,
      // Tạo hiệu ứng đổ bóng nhẹ
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bo góc đẹp hơn
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

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn màu'),
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
              child: const Text('OK'),
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
