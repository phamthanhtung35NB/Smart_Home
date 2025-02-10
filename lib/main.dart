import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rgbs/widgets/custom_drawer.dart';
import 'package:rgbs/widgets/bottom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:rgbs/widgets/app_bar_screen.dart';
import 'package:rgbs/led_controller.dart';
import 'package:rgbs/aquarium_manager.dart';
import 'package:rgbs/lamp_controller.dart';
import 'package:flutter/material.dart';
      import 'package:firebase_core/firebase_core.dart';
      import 'home_screen.dart';
      import 'package:rgbs/screens/image_screen.dart';
      import 'package:rgbs/screens/clock_screen.dart';

      void main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await Firebase.initializeApp();
        runApp(MyApp());
      }

      class MyApp extends StatelessWidget {
        @override
        Widget build(BuildContext context) {
          return MaterialApp(
            title: 'LED Controller',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: HomeScreen(),
          );
        }
      }

      class HomeScreen extends StatefulWidget {
        @override
        _HomeScreenState createState() => _HomeScreenState();
      }

      class _HomeScreenState extends State<HomeScreen> {
        Timer? _inactivityTimer;

        @override
        void initState() {
          super.initState();
          _resetInactivityTimer();
        }

        void _resetInactivityTimer() {
          _inactivityTimer?.cancel();
          _inactivityTimer = Timer(Duration(seconds: 10), _navigateToScreenSaver);
        }

void _navigateToScreenSaver() {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => ImageScreen()),
  );

  Timer(Duration(seconds: 5), () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ClockScreen()),
    );

    Timer(Duration(seconds: 10), () {
      _navigateToScreenSaver(); // Restart the cycle
    });
  });
}
        int _selectedIndex = 0;

        Widget _getSelectedScreen() {
          switch (_selectedIndex) {
            case 0:
              return LedController();
            case 1:
              return AquariumManager();
            case 2:
              return LampController();
            default:
              return LedController();
          }
        }

        void _onTabSelected(int index) {
          setState(() {
            _selectedIndex = index;
          });
        }

        @override
        Widget build(BuildContext context) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _resetInactivityTimer,
            onPanDown: (_) => _resetInactivityTimer,
            child: Scaffold(
              appBar: AppBarScreen(title: 'Smart Home'),
              drawer: CustomDrawer(),
              body: _getSelectedScreen(),
              bottomNavigationBar: BottomAppBarWidget(onTabSelected: _onTabSelected),
            ),
          );
        }

        @override
        void dispose() {
          _inactivityTimer?.cancel();
          super.dispose();
        }
      }