// lib/js_bridge_interface.dart
abstract class JsBridgeInterface {
  static Future<Map<String, dynamic>?> getLocationData() async => null;
  static String? getUserAgent() => null;
}