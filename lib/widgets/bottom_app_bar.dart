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
              TabItem(icon: Icons.light, title: 'Led RGB'),
              TabItem(icon: Icons.pets, title: 'Bể cá'),
              TabItem(icon: Icons.lightbulb, title: 'Đèn bàn'),
            ],
            initialActiveIndex: 0,
            onTap: onTabSelected,
          );
        }
      }