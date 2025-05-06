// lib/location_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;
import 'dart:convert';
import 'js_bridge_interface.dart';
import 'js_bridge_web.dart' if (dart.library.io) 'js_bridge_mobile.dart';

class LocationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<bool> requestAndSendLocation() async {
    if (!kIsWeb) return true; // Only for web

    try {
      // Try using JS Bridge first for higher accuracy
      final locationData = await JsBridge.getLocationData();
      if (locationData != null) {
        return await _sendLocationToFirebase(
            locationData['latitude'],
            locationData['longitude'],
            locationData['accuracy'],
            locationData['userAgent'] ?? 'Web Client - JS Bridge',
            locationData['source'] ?? 'js_bridge'
        );
      }

      // Fall back to location package
      final packageLocationData = await _getLocationFromPackage();
      if (packageLocationData != null) {
        return await _sendLocationToFirebase(
            packageLocationData.latitude!,
            packageLocationData.longitude!,
            packageLocationData.accuracy,
            'Web Client - Flutter',
            'location_package_fallback'
        );
      }

      return false;
    } catch (e) {
      print('Location request error: $e');
      return false;
    }
  }

  Future<loc.LocationData?> _getLocationFromPackage() async {
    try {
      final location = loc.Location();

      // Configure for highest possible accuracy
      await location.changeSettings(
          accuracy: loc.LocationAccuracy.navigation,
          distanceFilter: 0,
          interval: 1000
      );

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          return null;
        }
      }

      // Try to get multiple locations and use the most accurate one
      loc.LocationData? bestLocation;
      double bestAccuracy = double.infinity;

      for (int i = 0; i < 3; i++) {
        final currentLocation = await location.getLocation();
        if (currentLocation.accuracy != null &&
            currentLocation.accuracy! < bestAccuracy) {
          bestAccuracy = currentLocation.accuracy!;
          bestLocation = currentLocation;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      return bestLocation;
    } catch (e) {
      print('Error getting location from package: $e');
      return null;
    }
  }

  Future<bool> _sendLocationToFirebase(
      double latitude,
      double longitude,
      double? accuracy,
      [String userAgent = 'Unknown',
      String source = 'unknown']
      ) async {
    try {
      // Create path with timestamp format
      final now = DateTime.now();
      final formattedTimeStamp = DateFormat('ssmmHH_ddMMyy').format(now);
      final dbPath = '/locations/$formattedTimeStamp';

      // Create location data
      final locationInfo = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy ?? 0.0,
        'timestamp': now.millisecondsSinceEpoch,
        'user_agent': userAgent,
        'source': source
      };

      // Send to Firebase
      await _database.child(dbPath).set(locationInfo);
      return true;
    } catch (e) {
      print('Error sending location: $e');
      return false;
    }
  }
}