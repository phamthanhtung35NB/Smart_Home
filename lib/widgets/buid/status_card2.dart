
import 'package:flutter/material.dart';
class StatusCard2 extends StatelessWidget {
  final String title;
  final String thietBi;
  final bool status;
  final Function(String, dynamic) updateDatabase;
  final VoidCallback onTap;
  StatusCard2({
    required this.title,
    required this.thietBi,
    required this.status,
    required this.updateDatabase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap, // Add this line
        child: Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Trạng thái: ",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      status ? 'Bật' : 'Tắt',
                      style: TextStyle(
                        fontSize: 15,
                        color: status ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      status ? Icons.check_circle : Icons.cancel,
                      color: status ? Colors.green : Colors.grey,
                      size: 22,
                    ),
                    Switch(
                      value: status,
                      onChanged: (value) {
                        updateDatabase(thietBi, value);
                      },
                      activeColor: Colors.yellow,
                      inactiveThumbColor: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );

  }
}