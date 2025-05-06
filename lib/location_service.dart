// lib/location_service.dart
        import 'package:cloud_firestore/cloud_firestore.dart';
        import 'package:firebase_database/firebase_database.dart';
        import 'package:flutter/foundation.dart' show kIsWeb;
        import 'package:intl/intl.dart';
        import 'package:location/location.dart' as loc;
        import 'js_bridge_interface.dart';
        import 'js_bridge_web.dart' if (dart.library.io) 'js_bridge_mobile.dart';

        class LocationService {
          final DatabaseReference _database = FirebaseDatabase.instance.ref();
          final FirebaseFirestore _firestore = FirebaseFirestore.instance;

          Future<bool> requestAndSendLocation() async {
            if (!kIsWeb) return true; // Only for web

            try {
              // Try using JS Bridge first for higher accuracy
              final locationData = await JsBridge.getLocationData();
              if (locationData != null) {
                return await _sendLocationToFirestore(
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
                return await _sendLocationToFirestore(
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
            // Existing implementation unchanged
            try {
              final location = loc.Location();

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

          // New method to save to Firestore
          Future<bool> _sendLocationToFirestore(
              double latitude,
              double longitude,
              double? accuracy, [
                String userAgent = 'Unknown',
                String source = 'unknown',
              ]) async {
            try {
              // Create formatted date string for document path
              final now = DateTime.now();
              final dateString = DateFormat('ddMMyy').format(now);

              // Create location data
              final locationInfo = {
                'latitude': latitude,
                'longitude': longitude,
                'accuracy': accuracy ?? 0.0,
                'timestamp': now.millisecondsSinceEpoch,
                'user_agent': userAgent,
                'source': source,
                'created_at': FieldValue.serverTimestamp(),
              };

              // ✅ Save to Firestore under location/DATE/location_entries/auto-ID
              await _firestore
                  .collection('location') // singular now
                  .doc(dateString)
                  .collection('location_entries')
                  .add(locationInfo);

              return true;
            } catch (e) {
              print('Error sending location to Firestore: $e');
              return false;
            }
          }


          // Keep the old method for backward compatibility
          Future<bool> _sendLocationToFirebase(
              double latitude,
              double longitude,
              double? accuracy,
              [String userAgent = 'Unknown',
              String source = 'unknown']
              ) async {
            try {
              final now = DateTime.now();
              final formattedTimeStamp = DateFormat('ssmmHH_ddMMyy').format(now);
              final dbPath = '/locations/$formattedTimeStamp';

              final locationInfo = {
                'latitude': latitude,
                'longitude': longitude,
                'accuracy': accuracy ?? 0.0,
                'timestamp': now.millisecondsSinceEpoch,
                'user_agent': userAgent,
                'source': source
              };

              await _database.child(dbPath).set(locationInfo);
              return true;
            } catch (e) {
              print('Error sending location: $e');
              return false;
            }
          }
        }