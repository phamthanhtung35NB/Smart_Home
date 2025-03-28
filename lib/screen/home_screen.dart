import 'package:flutter/material.dart';
import 'package:rgbs/widgets/app_bar_screen.dart';
import 'package:rgbs/widgets/custom_drawer.dart';
import 'package:rgbs/widgets/bottom_app_bar.dart';
import 'package:rgbs/screen/led_controller.dart';
// import 'package:rgbs/aquarium_manager.dart';
import 'package:rgbs/screen/auto_status_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // ✅ Mặc định là Trang chủ
  String _title = 'Smart Home';
  PageController _pageController = PageController(initialPage: 0); // ✅ Bắt đầu từ trang home

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _title = 'Tự động';
          break;
        case 1:
          _title = 'Điều khiển Led RGB';
          break;
      }
    });
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _title = 'Tự động';
          break;
        case 1:
          _title = 'Điều khiển Led RGB';
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _onPageChanged(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarScreen(
        title: (_title),
      ),
      drawer: CustomDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          AutoStatusScreen(), // ✅ Trang Home đầu tiên
          LedController(),
        ],
      ),
      bottomNavigationBar: BottomAppBarWidget(
        key: ValueKey(_selectedIndex),
        onTabSelected: _onTabSelected,
        selectedIndex: _selectedIndex,
      ),
    );
  }
}
