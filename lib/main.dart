import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/router/app_router.dart';
import 'package:salamanca/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Маршрут '/map-test' ведёт на прототип карты, который остался в этом файле.
  static final GoRouter _router = createAppRouter(
    extraRoutes: [
      GoRoute(
        path: '/map-test',
        builder: (context, state) => const MapTestScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Salamanca',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}

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
      appBar: AppBar(title: const Text('Тест карты (SVG)')),
      body: Container(
        color: Colors.grey[200],
        child: InteractiveViewer(
          transformationController: _controller,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 5.0,
          constrained: false,
          child: SizedBox(
            width: 1500,
            height: 1500,
            child: SvgPicture.asset(
              'assets/images/map.svg',
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