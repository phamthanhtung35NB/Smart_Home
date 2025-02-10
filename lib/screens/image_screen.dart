import 'package:flutter/material.dart';
        import 'package:rgbs/home_screen.dart';

        class ImageScreen extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Scaffold(
              body: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: Center(
                  child: Image.asset('assets/images/screen_saver_image.png'), // Thay thế bằng đường dẫn hình ảnh của bạn
                ),
              ),
            );
          }
        }