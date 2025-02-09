import 'package:flutter/material.dart';
import 'package:rgbs/widgets/custom_drawer.dart';
import 'package:rgbs/widgets/bottom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:rgbs/led_controller.dart';

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
        // return ;
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
      appBar: AppBar(
        title: Text('Home'),
      ),
      drawer: CustomDrawer(),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomAppBarWidget(onTabSelected: _onTabSelected),
    );
  }
}