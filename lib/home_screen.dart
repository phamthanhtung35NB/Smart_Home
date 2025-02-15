import 'package:flutter/material.dart';
import 'package:rgbs/widgets/custom_drawer.dart';
import 'package:rgbs/widgets/bottom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:rgbs/widgets/app_bar_screen.dart';
import 'package:rgbs/led_controller.dart';
import 'package:rgbs/aquarium_manager.dart';
import 'package:rgbs/lamp_controller.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      appBar: AppBarScreen(title: 'Smart Home'),
      drawer: CustomDrawer(),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomAppBarWidget(onTabSelected: _onTabSelected),
    );
  }
}