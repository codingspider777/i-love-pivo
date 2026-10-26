import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salamanca/features/map/models/map_building.dart';

/// Размер SVG-карты (должен совпадать с viewBox в main_map.svg).
const double kMapSize = 1500;

/// ВЫКЛЮЧИЛ ОТЛАДКУ, чтобы красные рамки не мешали смотреть названия.
/// Если снова понадобится настраивать координаты, просто поменяй на true.
const bool kShowHitboxes = false;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focusBuildingId});

  final String? focusBuildingId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _anim;
  Size _viewport = Size.zero;
  String? _selectedId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _selectedId = widget.focusBuildingId;
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _fitMatrix() {
    final s = (_viewport.shortestSide / kMapSize);
    final dx = (_viewport.width - kMapSize * s) / 2;
    final dy = (_viewport.height - kMapSize * s) / 2;
    return Matrix4.translationValues(dx, dy, 0)
        .multiplied(Matrix4.diagonal3Values(s, s, 1));
  }

  Matrix4 _focusMatrix(Offset point, double scale) {
    final tx = _viewport.width / 2 - point.dx * scale;
    final ty = _viewport.height / 2 - point.dy * scale;
    return Matrix4.translationValues(tx, ty, 0)
        .multiplied(Matrix4.diagonal3Values(scale, scale, 1));
  }

  void _animateTo(Matrix4 target) {
    final tween = Matrix4Tween(begin: _controller.value, end: target);
    final curved = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    void listener() => _controller.value = tween.evaluate(curved);
    _anim
      ..reset()
      ..addListener(listener)
      ..forward().whenComplete(() => _anim.removeListener(listener));
  }

  void _focusBuilding(MapBuilding b, {bool animate = true}) {
    final target = _focusMatrix(b.center, 2.5);
    if (animate) {
      _animateTo(target);
    } else {
      _controller.value = target;
    }
  }

  void _onBuildingTap(MapBuilding b) {
    setState(() => _selectedId = b.id);
    _focusBuilding(b);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _BuildingSheet(building: b),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  void _initCamera(List<MapBuilding> buildings) {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final id = widget.focusBuildingId;
      final target = buildings.where((b) => b.id == id).firstOrNull;
      if (target != null) {
        _focusBuilding(target, animate: false);
      } else {
        _controller.value = _fitMatrix();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Карта кампуса')),
      body: buildingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Не удалось загрузить карту: $e')),
        data: (buildings) => LayoutBuilder(
          builder: (context, constraints) {
            _viewport = constraints.biggest;
            _initCamera(buildings);
            return ClipRect(
              child: InteractiveViewer(
                transformationController: _controller,
                constrained: false,
                minScale: 0.2,
                maxScale: 6,
                boundaryMargin: const EdgeInsets.all(200),
                child: SizedBox(
                  width: kMapSize,
                  height: kMapSize,
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        'assets/images/main_map.svg',
                        width: kMapSize,
                        height: kMapSize,
                      ),
                      // Цикл по зданиям: добавляем и хитбокс, и текст
                      for (final b in buildings) ...[
                        // 1. Невидимая кнопка для обработки нажатий
                        Positioned.fromRect(
                          rect: b.rect,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _onBuildingTap(b),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: b.id == _selectedId
                                    ? scheme.secondary.withValues(alpha: 0.45)
                                    : null,
                                border: kShowHitboxes
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                              ),
                              child: kShowHitboxes
                                  ? FittedBox(
                                      child: Text(
                                        b.id,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // 2. Текст с названием здания
                        Positioned(
                          left: b.center.dx - 80, // Центрируем текст (ширина 160)
                          top: b.center.dy - 10,   // Чуть выше центра здания
                          width: 160,
                          // IgnorePointer нужен, чтобы текст не перехватывал клики
                          child: IgnorePointer(
                            child: Text(
                              b.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                shadows: [
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Показать всю карту',
        onPressed: () => _animateTo(_fitMatrix()),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}

class _BuildingSheet extends StatelessWidget {
  const _BuildingSheet({required this.building});

  final MapBuilding building;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(building.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              building.description.isEmpty
                  ? 'Описание пока не добавлено'
                  : building.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}