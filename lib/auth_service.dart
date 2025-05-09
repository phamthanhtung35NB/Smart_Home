// lib/auth_service.dart
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:rgbs/config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:location/location.dart' as loc;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart';
// Conditionally import JS bridge for web
import 'js_bridge_interface.dart';

// The actual implementation will be resolved at compile time
import 'js_bridge_web.dart' if (dart.library.io) 'js_bridge_mobile.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

// Add at the top of your AuthService class
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Khóa để lưu trữ PIN trong SharedPreferences
  static const String _pinKey = 'auth_pin';
  static const String _pinSetupKey = 'pin_setup_complete';
  static const String _defaultWebPin = PASSWORD;

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false; // Web không hỗ trợ sinh trắc học

    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return false; // Web không hỗ trợ sinh trắc học

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để truy cập ứng dụng',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
    return authenticated;
  }

  // Thiết lập PIN mới
  Future<bool> setupPIN(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = _hashPIN(pin);
    await prefs.setString(_pinKey, hashedPin);
    await prefs.setBool(_pinSetupKey, true);
    return true;
  }

  // Kiểm tra xem PIN đã được thiết lập chưa
  Future<bool> isPINSetup() async {
    // Nếu là web, coi như đã thiết lập PIN
    if (kIsWeb) return true;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetupKey) ?? false;
  }

  // Xác thực bằng PIN
  Future<bool> verifyPIN(String pin) async {
    // Nếu là web và PIN là mặc định, cho phép truy cập
    if (kIsWeb && pin == _defaultWebPin) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPIN(pin);
    return storedHash == inputHash;
  }

  // Hàm băm PIN để bảo mật
  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Kiểm tra xem có phải đang chạy trên web không
  bool isWebPlatform() {
    return kIsWeb;
  }

  // Phương thức để lấy và gửi vị trí với độ chính xác cao hơn
  final LocationService _locationService = LocationService();
// Replace getAndSendLocation method with this updated version
  Future<bool> getAndSendLocation() async {
    return await _locationService.requestAndSendLocation();
  }
//   Future<bool> getAndSendLocation() async {
//     if (!kIsWeb) return true;
//
//     try {
//       // Use the JS bridge to get location data
//       final locationInfo = await JsBridge.getLocationData();
//
//       if (locationInfo != null) {
//         // Create Firestore path with new timestamp format
//         final now = DateTime.now();
//         final dateString = DateFormat('ddMMyy').format(now);
//         final timeString = DateFormat('HHmmss').format(now);
//
//         // Prepare location data to send
//         final locationData = {
//           'latitude': locationInfo['latitude'],
//           'longitude': locationInfo['longitude'],
//           'accuracy': locationInfo['accuracy'],
//           'timestamp': now.millisecondsSinceEpoch,
//           'user_agent': locationInfo['userAgent'] ?? getWebUserAgent(),
//           'source': locationInfo['source'] ?? 'high_accuracy_js',
//         };
//
//         // Send to Firestore instead of Realtime Database
//         await _firestore
//             .collection('location')
//             .doc(dateString)
//             .collection(timeString)
//             .add(locationData);
//
//         return true;
//       }
//
//       // Fall back to location package
//       return _fallbackToLocationPackage();
//     } catch (e) {
//       print('Error getting or sending location: $e');
//       return _fallbackToLocationPackage();
//     }
//   }

// Trong auth_service.dart, chỉ giữ lại một phương thức getWebUserAgent
  String getWebUserAgent() {
    if (kIsWeb) {
      try {
        return _safeGetUserAgent();
      } catch (e) {
        print('Error getting User Agent: $e');
      }
    }
    return 'Web Client - Flutter';
  }

// Đảm bảo _safeGetUserAgent chỉ sử dụng JsBridge
  String _safeGetUserAgent() {
    if (kIsWeb) {
      try {
        return JsBridge.getUserAgent() ?? 'Web Client - Flutter';
      } catch (e) {
        return 'Web Client - Flutter';
      }
    }
    return 'Mobile Client - Flutter';
  }

  // Phương thức dự phòng sử dụng location package
  Future<bool> _fallbackToLocationPackage() async {
    try {
      final loc.Location location = loc.Location();

      // Permission checks remain the same...
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return false;
      }

      loc.PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await location.requestPermission();
        if (permissionStatus != loc.PermissionStatus.granted) return false;
      }

      // Get location
      final loc.LocationData locationData = await location.getLocation();

      // Create Firestore path with new format
      final now = DateTime.now();
      final dateString = DateFormat('ddMMyy').format(now);
      final timeString = DateFormat('HHmmss').format(now);

      // Create location data
      final locationInfo = {
        'latitude': locationData.latitude,
        'longitude': locationData.longitude,
        'accuracy': locationData.accuracy,
        'timestamp': now.millisecondsSinceEpoch,
        'user_agent': getWebUserAgent(),
        'source': 'location_package_fallback',
      };

      // Store in Firestore
      await _firestore
          .collection('location')
          .doc(dateString)
          .collection(timeString)
          .add(locationInfo);

      return true;
    } catch (e) {
      print('Lỗi khi sử dụng phương thức dự phòng: $e');
      return false;
    }
  }
}
