import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('SVG Test')),
        body: Center(
          child: SvgPicture.asset(
            'assets/images/test.svg',
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}