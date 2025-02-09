import 'package:flutter/material.dart';
      import 'package:convex_bottom_bar/convex_bottom_bar.dart';

      class BottomAppBarWidget extends StatelessWidget {
        final Function(int) onTabSelected;

        const BottomAppBarWidget({super.key, required this.onTabSelected});

        @override
        Widget build(BuildContext context) {
          return ConvexAppBar(
            style: TabStyle.reactCircle,
            items: [
              TabItem(icon: Icons.location_disabled, title: 'List Lecturers'),
              TabItem(icon: Icons.home, title: 'Home'),
            ],
            initialActiveIndex: 0,
            onTap: onTabSelected,
          );
        }
      }