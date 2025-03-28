import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:location/location.dart' as loc;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
// import 'package:flutter_js/flutter_js.dart';
import 'dart:convert'; // Add this import for jsonDecode

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isAuthenticating = false;
  bool _biometricFailed = false;
  bool _isPinVerified = false;
  bool _isCheckingLocation = false;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    // Kiểm tra xem đã thiết lập PIN chưa
    bool isPINSetup = await _authService.isPINSetup();

    if (!isPINSetup) {
      // Nếu chưa thiết lập PIN, chuyển đến màn hình thiết lập PIN
      _navigateToPINSetup();
      return;
    }

    // Nếu là web, hiển thị màn hình nhập PIN
    if (kIsWeb) {
      setState(() {
        _biometricFailed = true;
      });
      return;
    }

    // Nếu đã thiết lập PIN, kiểm tra có thể sử dụng sinh trắc học không
    bool canUseBiometric = await _authService.isBiometricAvailable();

    if (canUseBiometric) {
      // Nếu có sinh trắc học, thử xác thực
      _authenticateWithBiometrics();
    } else {
      // Nếu không có sinh trắc học, hiển thị màn hình nhập PIN
      setState(() {
        _biometricFailed = true;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isAuthenticating = true;
    });

    bool authenticated = await _authService.authenticate();

    setState(() {
      _isAuthenticating = false;
      _biometricFailed = !authenticated;
    });

    if (authenticated) {
      _navigateToHome();
    }
  }

  void _navigateToPINSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => PINSetupScreen()),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> _verifyPIN() async {
    String pin = _pinController.text;
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mã PIN phải có ít nhất 4 số')),
      );
      return;
    }

    bool verified = await _authService.verifyPIN(pin);

    if (verified) {
      setState(() {
        _isPinVerified = true;
      });

      // Nếu là web, yêu cầu vị trí
      if (kIsWeb) {
        _requestAndVerifyLocation();
      } else {
        _navigateToHome();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mã PIN không đúng')),
      );
      _pinController.clear();
    }
  }

  Future<void> _requestAndVerifyLocation() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      bool locationSuccess = await _authService.getAndSendLocation();

      if (!mounted) return;

      setState(() {
        _isCheckingLocation = false;
      });

      if (locationSuccess) {
        // Show success message before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vị trí đã được xác minh thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Short delay to show the success message
        await Future.delayed(Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        setState(() {
          _isPinVerified = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Không thể xác minh vị trí. Vui lòng cho phép truy cập vị trí và thử lại.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _requestAndVerifyLocation,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingLocation = false;
        _isPinVerified = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildLocationRequestScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 70, color: Colors.blue),
        SizedBox(height: 20),
        Text(
          'Xác minh vị trí',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Ứng dụng cần xác minh vị trí của bạn để đảm bảo an toàn.\n'
            'Hãy chắc chắn bạn đã bật GPS và cho phép truy cập vị trí chính xác.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        SizedBox(height: 25),
        _isCheckingLocation
            ? Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    'Đang xác minh vị trí...\n'
                    'Quá trình này có thể mất vài giây',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                icon: Icon(Icons.gps_fixed),
                label: Text('Xác minh vị trí'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _requestAndVerifyLocation,
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromRGBO(33, 150, 243, 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isPinVerified
                    ? _buildLocationRequestScreen()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_biometricFailed) ...[
                            Icon(Icons.fingerprint,
                                size: 80, color: Colors.blue),
                            SizedBox(height: 20),
                            Text(
                              'Xác thực bằng vân tay',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 30),
                            if (_isAuthenticating)
                              CircularProgressIndicator()
                            else
                              ElevatedButton(
                                onPressed: _authenticateWithBiometrics,
                                child: Text('Xác thực để tiếp tục'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(200, 50),
                                ),
                              ),
                            SizedBox(height: 20),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _biometricFailed = true;
                                });
                              },
                              child: Text('Sử dụng mã PIN'),
                            ),
                          ] else ...[
                            Icon(Icons.pin, size: 60, color: Colors.blue),
                            SizedBox(height: 20),
                            Text(
                              'Nhập mã PIN',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (kIsWeb) ...[
                              SizedBox(height: 10),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Phiên bản web: Sử dụng mã PIN',
                                  style:
                                      TextStyle(color: Colors.orange.shade800),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            SizedBox(height: 20),
                            TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelText: 'Mã PIN',
                                counterText: '',
                                prefixIcon: Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _verifyPIN,
                              child: Text('Xác thực'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            FutureBuilder<bool>(
                              future: _authService.isBiometricAvailable(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data == true) {
                                  return TextButton.icon(
                                    icon: Icon(Icons.fingerprint),
                                    label: Text('Sử dụng vân tay'),
                                    onPressed: () {
                                      setState(() {
                                        _biometricFailed = false;
                                      });
                                      _authenticateWithBiometrics();
                                    },
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
