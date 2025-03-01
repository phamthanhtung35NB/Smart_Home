// lib/js_bridge_mobile.dart
import 'js_bridge_interface.dart';

class JsBridge implements JsBridgeInterface {
  static Future<Map<String, dynamic>?> getLocationData() async {
    // Mobile devices don't use JavaScript
    return null;
  }

  static String? getUserAgent() {
    return null;
  }
}