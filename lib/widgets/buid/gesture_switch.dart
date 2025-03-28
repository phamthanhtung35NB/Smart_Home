// lib/widgets/gesture_switch.dart
import 'package:flutter/material.dart';

class GestureSwitch extends StatelessWidget {
  final bool autoSystem;
  final ValueChanged<bool> onChanged;

  GestureSwitch({required this.autoSystem, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) {
          // Swipe right
          onChanged(true);
        } else if (velocity < 0) {
          // Swipe left
          onChanged(false);
        }
      },
      child: AnimatedContainer(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 300),
        width: 280,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(39),
          color: autoSystem ? Colors.green : Colors.grey.shade400,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: autoSystem ? 200 : 0,
              top: 0,
              bottom: 0,
              right: autoSystem ? 0 : 200,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 29,
                      offset: Offset(0, 6),
                    )
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                autoSystem ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}