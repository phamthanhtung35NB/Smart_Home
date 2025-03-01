import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart';

class PINSetupScreen extends StatefulWidget {
  @override
  _PINSetupScreenState createState() => _PINSetupScreenState();
}

class _PINSetupScreenState extends State<PINSetupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorMessage;

  Future<void> _setupPIN() async {
    String pin = _pinController.text;
    String confirmPin = _confirmPinController.text;

    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Mã PIN phải có ít nhất 4 số';
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        _errorMessage = 'Mã PIN không khớp';
      });
      return;
    }

    bool success = await _authService.setupPIN(pin);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Không thể thiết lập PIN. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thiết lập mã PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tạo mã PIN để truy cập ứng dụng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nhập mã PIN mới',
                counterText: '',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Xác nhận mã PIN',
                counterText: '',
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 15),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ],
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _setupPIN,
              child: Text('Xác nhận'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}