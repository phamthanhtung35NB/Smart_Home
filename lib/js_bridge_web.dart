// lib/js_bridge_web.dart
        import 'js_bridge_interface.dart';
        import 'dart:async';
        import 'dart:convert';
        import 'dart:js' as js;

        class JsBridge implements JsBridgeInterface {
          static String? getUserAgent() {
            try {
              return js.context['flutterWebUserAgent']?.toString();
            } catch (e) {
              print('Error getting user agent: $e');
              return null;
            }
          }

          static Future<Map<String, dynamic>?> getLocationData() async {
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