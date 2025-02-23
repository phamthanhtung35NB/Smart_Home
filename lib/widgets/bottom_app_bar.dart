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
              TabItem(icon: Icons.light, title: 'Led Controller'),
              TabItem(icon: Icons.pets, title: 'Aquarium Manager'),
              TabItem(icon: Icons.lightbulb, title: 'Lamp Controller'),
            ],
            initialActiveIndex: 0,
            onTap: onTabSelected,
          );
        }
      }