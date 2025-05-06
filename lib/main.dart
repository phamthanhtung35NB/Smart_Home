import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screen/auth_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
final DatabaseReference _database = FirebaseDatabase.instance.ref();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _initializeNotifications();
  await initializeService();

  runApp(MyApp());
}

Future<void> initializeService() async {

  if (kIsWeb) {
    print("Dịch vụ nền không được hỗ trợ trên nền tảng Web.");
    return; // Bỏ qua nếu là Web
  }
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService(); // Sửa lại từ `start()` thành `startService()`
}



@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  _database.child('aquarium/temperature').onValue.listen((event) {
    if (event.snapshot.value != null) {
      double temperature = (event.snapshot.value as num).toDouble();
      if (temperature >= 26||temperature<=23) {
        _sendPushNotification('Nhiệt độ hiện tại: $temperature°C, vượt ngưỡng!');
      }
    }
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}



void _initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> _sendPushNotification(String message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'temperature_alerts',
    'Temperature Alerts',
    channelDescription: 'Thông báo khi nhiệt độ vượt mức',
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification_sound'),
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Cảnh báo nhiệt độ',
    message,
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthScreen(),
    );
  }
}
