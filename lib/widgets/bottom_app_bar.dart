import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class BottomAppBarWidget extends StatelessWidget {
  final Function(int) onTabSelected;
  final int selectedIndex;

  const BottomAppBarWidget({
    super.key,
    required this.onTabSelected,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ConvexAppBar(
      key: ValueKey(selectedIndex),
      style: TabStyle.reactCircle,
      // activeColor: Colors.blue,
      items: [
        TabItem(icon: Icons.home, title: ''), // ✅ Trang Home đầu tiên
        TabItem(icon: Icons.auto_awesome, title: ''),
      ],
      initialActiveIndex: selectedIndex,
      onTap: onTabSelected,
    );
  }
}
