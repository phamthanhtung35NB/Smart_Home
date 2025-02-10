// // flip_number.dart
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
//
// class FlipNumber extends StatelessWidget {
//   final String number;
//   final double height;
//   final double width;
//
//   const FlipNumber({
//     Key? key,
//     required this.number,
//     this.height = 80,
//     this.width = 60,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width,
//       height: height,
//       margin: const EdgeInsets.symmetric(horizontal: 2),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Center(
//         child: Text(
//           number,
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: height * 0.7,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class FlipAnimation extends StatefulWidget {
//   final String startNumber;
//   final String endNumber;
//   final double height;
//   final double width;
//
//   const FlipAnimation({
//     Key? key,
//     required this.startNumber,
//     required this.endNumber,
//     this.height = 80,
//     this.width = 60,
//   }) : super(key: key);
//
//   @override
//   State<FlipAnimation> createState() => _FlipAnimationState();
// }
//
// class _FlipAnimationState extends State<FlipAnimation> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _animation = Tween<double>(begin: 0, end: -math.pi).animate(_controller);
//     _controller.forward();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         final value = _animation.value;
//         final transform = Matrix4.identity()
//           ..setEntry(3, 2, 0.001)
//           ..rotateX(value);
//
//         return Container(
//           height: widget.height,
//           width: widget.width,
//           child: Transform(
//             transform: transform,
//             alignment: Alignment.center,
//             child: FlipNumber(
//               number: value > -math.pi/2 ? widget.startNumber : widget.endNumber,
//               height: widget.height,
//               width: widget.width,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }