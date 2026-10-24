import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Прототип карты')),
      body: Container(
        color: Colors.grey[300],
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 0.5,
          maxScale: 5.0,
          constrained: false,
          
          child: SizedBox(
            width: 1500,
            height: 1500,
            child: SvgPicture.asset(
              'assets/images/test.svg', 
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.value = Matrix4.identity(); 
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}