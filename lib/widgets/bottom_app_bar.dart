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
              TabItem(icon: Icons.home, title: 'Auto Status'),
              TabItem(icon: Icons.pets, title: 'Aquarium'),
              TabItem(icon: Icons.lightbulb, title: 'Lamp'),
              TabItem(icon: Icons.light, title: 'Led Controller'),
            ],
            initialActiveIndex: 0,
            onTap: onTabSelected,
          );
        }
      }