import 'package:flutter/material.dart';
import 'package:rgbs/widgets/app_bar_screen.dart';
import 'package:rgbs/widgets/custom_drawer.dart';
import 'package:rgbs/widgets/bottom_app_bar.dart';
import 'package:rgbs/screen/led_controller.dart';

// import 'package:rgbs/aquarium_manager.dart';
import 'package:rgbs/screen/auto_status_screen.dart';
import 'location_history_screen.dart';
import 'web_view_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // ✅ Mặc định là Trang chủ
  String _title = 'Bể cá';
  PageController _pageController =
      PageController(initialPage: 0); // ✅ Bắt đầu từ trang home

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _title = 'Bể cá';
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
          _title = 'Bể cá';
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
    // For web platform, show the view-only version
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBarScreen(
          title: 'Hệ thống bể cá (Chế độ xem)',
        ),
        body: WebViewScreen(),
      );
    }
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
          LocationHistoryScreen() // trang lịch sử vị trí
          // LedController(),
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
