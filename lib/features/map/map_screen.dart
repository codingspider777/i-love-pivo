import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salamanca/features/map/models/map_building.dart';
import 'package:salamanca/features/map/widgets/building_sheet.dart'; // даёт categoryIcon
import 'package:salamanca/shared/widgets/app_choice_chip.dart';

const double kMapSize = 1500;
const double kLabelsMinScale = 1.4;
const double kHitSlop = 10;
const double kMaxScale = 8.0;

/// Область, которую реально занимает рисунок карты в SVG (координаты 0..kMapSize).
/// Минимальный зум = эта область целиком на экране. Если в SVG есть пустые
/// поля по краям — подгоните прямоугольник под рисунок.
const Rect kMapContent = Rect.fromLTWH(0, 0, kMapSize, kMapSize);

/// Высота панели фильтров поверх карты (карта «целиком» вписывается под неё).
const double kTopInset = 52;

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
  VoidCallback? _animListener;

  Size _viewport = Size.zero;
  double _fitScale = 0.5;
  String? _selectedId;
  bool _isInitialized = false;

  // состояние жеста
  double _startScale = 1;
  Offset _startScene = Offset.zero;
  Offset _lastFocal = Offset.zero;
  Offset _doubleTapPos = Offset.zero;

  /// Выбранные категории. Пустой набор = показывать все.
  final Set<BuildingCategory> _filters = {};

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this);
    _selectedId = widget.focusBuildingId;
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get _scale => _controller.value.storage[0];

  // ---------- матрицы ----------

  /// Ограничивает сдвиг, чтобы карта не уезжала за экран.
  /// Если карта меньше экрана — центрирует её.
  Matrix4 _clampMatrix(Matrix4 m) {
    if (_viewport == Size.zero) return m;
    final s = m.storage[0];
    final t = m.getTranslation();
    final c = kMapContent;
    final availH = _viewport.height - kTopInset;

    final double dx;
    if (c.width * s <= _viewport.width) {
      dx = (_viewport.width - c.width * s) / 2 - c.left * s;
    } else {
      dx = t.x.clamp(_viewport.width - c.right * s, -c.left * s).toDouble();
    }

    final double dy;
    if (c.height * s <= availH) {
      dy = kTopInset + (availH - c.height * s) / 2 - c.top * s;
    } else {
      dy = t.y
          .clamp(_viewport.height - c.bottom * s, kTopInset - c.top * s)
          .toDouble();
    }

    return Matrix4.translationValues(dx, dy, 0)..scale(s, s, 1.0);
  }

  /// Матрица, при которой точка [scene] карты окажется в [screen].
  Matrix4 _anchored(double scale, Offset scene, Offset screen) {
    final t = screen - scene * scale;
    return _clampMatrix(
        Matrix4.translationValues(t.dx, t.dy, 0)..scale(scale, scale, 1.0));
  }

  /// Вся карта целиком, по центру.
  Matrix4 _fitMatrix() =>
      _clampMatrix(Matrix4.diagonal3Values(_fitScale, _fitScale, 1));

  Matrix4 _focusMatrix(Offset point, double scale) => _anchored(
        scale,
        point,
        Offset(_viewport.width / 2,
            kTopInset + (_viewport.height - kTopInset) / 2),
      );

  // ---------- анимация ----------

  void _animateTo(
    Matrix4 target, {
    Duration duration = const Duration(milliseconds: 380),
    Curve curve = Curves.easeOutCubic,
  }) {
    _anim.stop();
    final old = _animListener;
    if (old != null) _anim.removeListener(old);

    final tween = Matrix4Tween(begin: _controller.value, end: target);
    final curved = CurvedAnimation(parent: _anim, curve: curve);
    void listener() => _controller.value = tween.evaluate(curved);
    _animListener = listener;

    _anim.duration = duration;
    _anim.addListener(listener);
    _anim.forward(from: 0);
  }

  void _focusBuilding(MapBuilding b, {bool animate = true}) {
    final s = math.max(_scale, 2.5).clamp(_fitScale, kMaxScale).toDouble();
    final target = _focusMatrix(b.center, s);
    if (animate) {
      _animateTo(target);
    } else {
      _controller.value = target;
    }
  }

  // ---------- жесты ----------

  void _onScaleStart(ScaleStartDetails d) {
    _anim.stop();
    _startScale = _scale;
    _startScene = _controller.toScene(d.localFocalPoint);
    _lastFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    _lastFocal = d.localFocalPoint;
    // «резиновые» пределы: чуть дальше допустимого, потом вернётся
    final s = (_startScale * d.scale)
        .clamp(_fitScale * 0.8, kMaxScale * 1.2)
        .toDouble();
    _controller.value = _anchored(s, _startScene, d.localFocalPoint);
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final s = _scale;
    final limited = s.clamp(_fitScale, kMaxScale).toDouble();

    if ((s - limited).abs() > 0.001) {
      // вернуть из «резины» к допустимому масштабу
      final scene = _controller.toScene(_lastFocal);
      _animateTo(_anchored(limited, scene, _lastFocal),
          duration: const Duration(milliseconds: 260));
      return;
    }

    // инерция после панорамирования
    final v = d.velocity.pixelsPerSecond;
    if (d.pointerCount == 0 && v.distance > 200) {
      final t = _controller.value.getTranslation();
      final target = _clampMatrix(
        Matrix4.translationValues(
            t.x + v.dx * 0.25, t.y + v.dy * 0.25, 0)
          ..scale(s, s, 1.0),
      );
      _animateTo(target,
          duration: const Duration(milliseconds: 550),
          curve: Curves.decelerate);
    }
  }

  void _onDoubleTap() {
    final scene = _controller.toScene(_doubleTapPos);
    if (_scale > _fitScale * 1.3) {
      _animateTo(_fitMatrix());
    } else {
      final target = math.max(_fitScale * 3, 2.5).clamp(_fitScale, kMaxScale);
      _animateTo(_anchored(target.toDouble(), scene, _doubleTapPos));
    }
  }

  // ---------- тапы по зданиям ----------

  MapBuilding? _hitTest(List<MapBuilding> buildings, Offset scenePoint) {
    MapBuilding? best;
    var bestDist = double.infinity;

    for (final b in buildings) {
      bool isHit;
      if (b.polygon != null && b.polygon!.isNotEmpty) {
        final path = Path()..addPolygon(b.polygon!, true);
        isHit = path.contains(scenePoint);
      } else {
        final slop = kHitSlop / (_scale == 0 ? 1.0 : _scale);
        isHit = b.rect.inflate(slop).contains(scenePoint);
      }

      if (isHit) {
        final d = (b.center - scenePoint).distanceSquared;
        if (d < bestDist) {
          bestDist = d;
          best = b;
        }
      }
    }
    return best;
  }

  void _handleTap(List<MapBuilding> buildings, Offset viewportPoint) {
    final hit = _hitTest(buildings, _controller.toScene(viewportPoint));
    if (hit != null) _onBuildingTap(hit);
  }

  void _onBuildingTap(MapBuilding b) {
    setState(() => _selectedId = b.id);
    _focusBuilding(b);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return BuildingSheet(
              building: b,
              controller: scrollController,
              onClose: () => Navigator.pop(context),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selectedId = null);
    });
  }

  // ---------- build ----------

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
        data: (all) {
          final buildings = _filters.isEmpty
              ? all
              : [for (final b in all) if (_filters.contains(b.category)) b];

          return LayoutBuilder(
            builder: (context, constraints) {
              final currentSize = constraints.biggest;

              if (currentSize.width < 300 || currentSize.height < 300) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_viewport != currentSize) {
                _viewport = currentSize;
                _fitScale = math.min(
                  _viewport.width / kMapContent.width,
                  (_viewport.height - kTopInset) / kMapContent.height,
                );

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (!_isInitialized) {
                    _isInitialized = true;
                    final id = widget.focusBuildingId;
                    final target = all.where((b) => b.id == id).firstOrNull;
                    if (target != null) {
                      _focusBuilding(target, animate: false);
                    } else {
                      _controller.value = _fitMatrix();
                    }
                  } else {
                    // поворот экрана и т.п.
                    _controller.value = _scale < _fitScale
                        ? _fitMatrix()
                        : _clampMatrix(_controller.value);
                  }
                });
              }

              return Stack(
                children: [
                  GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      onScaleEnd: _onScaleEnd,
                      onTapUp: (d) => _handleTap(buildings, d.localPosition),
                      onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
                      onDoubleTap: _onDoubleTap,
                      child: ClipRect(
                        child: SizedBox.expand(
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                width: kMapSize,
                                height: kMapSize,
                                child: ValueListenableBuilder<Matrix4>(
                                  valueListenable: _controller,
                                  builder: (context, matrix, child) =>
                                      Transform(
                                    transform: matrix,
                                    alignment: Alignment.topLeft,
                                    child: child,
                                  ),
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
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        for (final b in buildings)
                                          if (b.id == _selectedId)
                                            if (b.polygon != null)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter:
                                                        _PolygonHighlightPainter(
                                                      polygon: b.polygon!,
                                                      color: scheme.secondary
                                                          .withValues(
                                                              alpha: 0.45),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              Positioned.fromRect(
                                                rect: b.rect,
                                                child: IgnorePointer(
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: scheme.secondary
                                                          .withValues(
                                                              alpha: 0.45),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                  ValueListenableBuilder<Matrix4>(
                    valueListenable: _controller,
                    builder: (context, matrix, _) {
                      final currentScale = matrix.storage[0];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final b in buildings)
                            _buildMarkerOverlay(
                              context: context,
                              b: b,
                              matrix: matrix,
                              currentScale: currentScale,
                              isDarkMode: isDarkMode,
                              scheme: scheme,
                            ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _CategoryFilterBar(
                      selected: _filters,
                      onToggle: (c) => setState(() {
                        _filters.contains(c)
                            ? _filters.remove(c)
                            : _filters.add(c);
                      }),
                      onClear: () => setState(_filters.clear),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Показать всю карту',
        onPressed: () => _animateTo(_fitMatrix()),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  Widget _buildMarkerOverlay({
    required BuildContext context,
    required MapBuilding b,
    required Matrix4 matrix,
    required double currentScale,
    required bool isDarkMode,
    required ColorScheme scheme,
  }) {
    final screenPos = MatrixUtils.transformPoint(matrix, b.center);

    if (screenPos.dx < -200 ||
        screenPos.dx > _viewport.width + 200 ||
        screenPos.dy < -200 ||
        screenPos.dy > _viewport.height + 200) {
      return const SizedBox.shrink();
    }

    final isSelected = b.id == _selectedId;
    final showLabel = currentScale >= kLabelsMinScale || isSelected;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: screenPos.dx - 22,
          top: screenPos.dy - 22,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onBuildingTap(b),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : scheme.surface,
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
                    color: isSelected ? scheme.onPrimary : scheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showLabel)
          Positioned(
            left: screenPos.dx - 65,
            top: screenPos.dy + 14,
            child: IgnorePointer(
              child: SizedBox(
                width: 130,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDarkMode
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
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final Set<BuildingCategory> selected;
  final ValueChanged<BuildingCategory> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          AppChoiceChip(
            label: 'Все',
            selected: selected.isEmpty,
            onSelected: (_) => onClear(),
          ),
          for (final c in BuildingCategory.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AppChoiceChip(
                label: c.label,
                icon: categoryIcon(c),
                selected: selected.contains(c),
                onSelected: (_) => onToggle(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _PolygonHighlightPainter extends CustomPainter {
  _PolygonHighlightPainter({required this.polygon, required this.color});
  final List<Offset> polygon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()..addPolygon(polygon, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PolygonHighlightPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.polygon != polygon;
}