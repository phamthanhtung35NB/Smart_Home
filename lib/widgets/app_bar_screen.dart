import 'package:flutter/material.dart';

class AppBarScreen extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppBarScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}