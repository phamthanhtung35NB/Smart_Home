// lib/js_bridge.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:js' as js;
import 'dart:convert';

class JsBridge {
  static Future<Map<String, dynamic>?> getLocationData() async {
    if (!kIsWeb) return null;

    try {
      final completer = Completer<Map<String, dynamic>>();

      js.context.callMethod('getLocationData', [
        js.allowInterop((dynamic data) {
          Map<String, dynamic> locationData = jsonDecode(data);
          completer.complete(locationData);
        }),
        js.allowInterop((dynamic error) {
          completer.completeError(error.toString());
        })
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Location request timeout')
      );
    } catch (e) {
      print('JavaScript location error: $e');
      return null;
    }
  }
}