import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Здание на карте. Координаты — в системе SVG (viewBox 0 0 1500 1500).
class MapBuilding {
  const MapBuilding({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;
  final double x;
  final double y;
  final double width;
  final double height;

  Rect get rect => Rect.fromLTWH(x, y, width, height);
  Offset get center => rect.center;

  factory MapBuilding.fromJson(Map<String, dynamic> json) => MapBuilding(
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );
}

/// Загружает assets/data/buildings.json один раз.
final buildingsProvider = FutureProvider<List<MapBuilding>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/buildings.json');
  final list = jsonDecode(raw) as List<dynamic>;
  return [
    for (final item in list) MapBuilding.fromJson(item as Map<String, dynamic>),
  ];
});