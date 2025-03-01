import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home_screen.dart'; // Đây là màn hình chính của ứng dụng sau khi xác thực thành công

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticateWithBiometrics();
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isAuthenticating = true;
    });

    bool canCheckBiometrics = await _authService.isBiometricAvailable();
    bool authenticated = false;

    if (canCheckBiometrics) {
      authenticated = await _authService.authenticate();
    }

    setState(() {
      _isAuthenticating = false;
    });

    if (authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Xác thực bằng vân tay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            if (_isAuthenticating)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _authenticateWithBiometrics,
                child: Text('Xác thực để tiếp tục'),
              ),
          ],
        ),
      ),
    );
  }
}