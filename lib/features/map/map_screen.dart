import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salamanca/features/map/models/map_building.dart';

/// Размер SVG-карты (должен совпадать с viewBox в main_map_light/dark.svg).
const double kMapSize = 1500;

/// Подписи маркеров показываются, начиная с этого масштаба.
const double kLabelsMinScale = 1.4;

/// Запас вокруг здания при попадании тапа (в пикселях экрана),
/// чтобы узкие здания было проще нажимать.
const double kHitSlop = 10;

IconData categoryIcon(BuildingCategory c) => switch (c) {
      BuildingCategory.academic => Icons.school,
      BuildingCategory.dorm => Icons.bed,
      BuildingCategory.sport => Icons.fitness_center,
      BuildingCategory.food => Icons.restaurant,
      BuildingCategory.service => Icons.place,
    };

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

  double get _scale => _controller.value.getMaxScaleOnAxis();

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

  // ---------------------------------------------------------------------
  // Тап по зданию: toScene + hit-test
  // ---------------------------------------------------------------------

  /// Находит здание под точкой [scenePoint] (координаты SVG).
  /// Если подходит несколько — берём то, чей центр ближе к точке.
  MapBuilding? _hitTest(List<MapBuilding> buildings, Offset scenePoint) {
    final slop = kHitSlop / _scale;
    MapBuilding? best;
    var bestDist = double.infinity;
    for (final b in buildings) {
      if (!b.rect.inflate(slop).contains(scenePoint)) continue;
      final d = (b.center - scenePoint).distanceSquared;
      if (d < bestDist) {
        bestDist = d;
        best = b;
      }
    }
    return best;
  }

  void _handleTap(List<MapBuilding> buildings, Offset viewportPoint) {
    // Переводим точку из координат вьюпорта в координаты сцены (SVG).
    final scenePoint = _controller.toScene(viewportPoint);
    final hit = _hitTest(buildings, scenePoint);
    if (hit != null) _onBuildingTap(hit);
  }

  void _onBuildingTap(MapBuilding b) {
    setState(() => _selectedId = b.id);
    _focusBuilding(b);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Карта кампуса')),
      body: buildingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Не удалось загрузить карту: $e')),
        data: (buildings) => LayoutBuilder(
          builder: (context, constraints) {
            _viewport = constraints.biggest;
            _initCamera(buildings);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (d) => _handleTap(buildings, d.localPosition),
              child: ClipRect(
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
                        ColoredBox(
                          color: isDarkMode
                              ? const Color(0xFF0B132B)
                              : const Color(0xFFF8FAFC),
                          child: SvgPicture.asset(
                            isDarkMode
                                ? 'assets/images/main_map_dark.svg'
                                : 'assets/images/main_map_light.svg',
                            width: kMapSize,
                            height: kMapSize,
                          ),
                        ),
                        // Подсветка выбранного здания.
                        for (final b in buildings)
                          if (b.id == _selectedId)
                            Positioned.fromRect(
                              rect: b.rect,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.secondary.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),
                        // Маркеры POI (Stack + Positioned).
                        IgnorePointer(
                          child: ValueListenableBuilder<Matrix4>(
                            valueListenable: _controller,
                            builder: (context, matrix, _) => _PoiLayer(
                              buildings: buildings,
                              scale: matrix.getMaxScaleOnAxis(),
                              selectedId: _selectedId,
                              isDark: isDarkMode,
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Слой маркеров. Маркеры и подписи компенсируют масштаб карты (1 / scale),
/// поэтому на экране всегда имеют постоянный размер.
class _PoiLayer extends StatelessWidget {
  const _PoiLayer({
    required this.buildings,
    required this.scale,
    required this.selectedId,
    required this.isDark,
  });

  final List<MapBuilding> buildings;
  final double scale;
  final String? selectedId;
  final bool isDark;

  static const double _markerSize = 24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inv = 1 / scale;

    return SizedBox(
      width: kMapSize,
      height: kMapSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final b in buildings) ...[
            // Круглый маркер по центру здания.
            Positioned(
              left: b.center.dx,
              top: b.center.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5),
                child: Transform.scale(
                  scale: inv,
                  child: Container(
                    width: _markerSize,
                    height: _markerSize,
                    decoration: BoxDecoration(
                      color: b.id == selectedId
                          ? scheme.primary
                          : scheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      categoryIcon(b.category),
                      size: 14,
                      color: b.id == selectedId
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            // Подпись под маркером: при приближении и для выбранного здания.
            if (scale >= kLabelsMinScale || b.id == selectedId)
              Positioned(
                left: b.center.dx,
                top: b.center.dy + (_markerSize / 2 + 2) * inv,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Transform.scale(
                    scale: inv,
                    alignment: Alignment.topCenter,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 130),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
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
    final scheme = theme.colorScheme;
    final b = building;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(categoryIcon(b.category), color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: theme.textTheme.titleLarge),
                      Text(
                        b.category.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (b.address.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        Text(b.address, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              b.description.isEmpty
                  ? 'Описание пока не добавлено'
                  : b.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}