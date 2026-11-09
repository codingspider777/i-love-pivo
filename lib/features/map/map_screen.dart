import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salamanca/features/map/models/map_building.dart';
import 'package:salamanca/features/map/widgets/building_sheet.dart'; // даёт categoryIcon
import 'package:salamanca/shared/widgets/app_choice_chip.dart';

const double kMapSize = 1500;
const double kLabelsMinScale = 1.4;
const double kHitSlop = 10;

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
  double _fitScale = 0.5;
  String? _selectedId;
  bool _isInitialized = false;
  bool _isAnimatingFocus = false;

  /// Выбранные категории. Пустой набор = показывать все.
  final Set<BuildingCategory> _filters = {};

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _selectedId = widget.focusBuildingId;
    _controller.addListener(_onMatrixChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onMatrixChanged);
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _clampMatrix(Matrix4 matrix) {
    if (_viewport == Size.zero) return matrix;

    final scale = matrix.getMaxScaleOnAxis();
    final clampedScale = scale.clamp(_fitScale, 6.0);

    final mapWidth = kMapSize * clampedScale;
    final mapHeight = kMapSize * clampedScale;

    double dx = matrix.getTranslation().x;
    double dy = matrix.getTranslation().y;

    if (mapWidth <= _viewport.width) {
      dx = (_viewport.width - mapWidth) / 2;
    } else {
      dx = dx.clamp(_viewport.width - mapWidth, 0.0);
    }

    if (mapHeight <= _viewport.height) {
      dy = (_viewport.height - mapHeight) / 2;
    } else {
      dy = dy.clamp(_viewport.height - mapHeight, 0.0);
    }

    return Matrix4.translationValues(dx, dy, 0)
        .multiplied(Matrix4.diagonal3Values(clampedScale, clampedScale, 1));
  }

  void _onMatrixChanged() {
    if (_isAnimatingFocus) return;
    if (_viewport == Size.zero) return;

    final matrix = _controller.value;
    final clamped = _clampMatrix(matrix);

    if (clamped != matrix) {
      _controller.value = clamped;
    }
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

  void _animateTo(Matrix4 target, {bool isFocus = false}) {
    final safeTarget = isFocus ? target : _clampMatrix(target);

    _isAnimatingFocus = isFocus;

    final tween = Matrix4Tween(begin: _controller.value, end: safeTarget);
    final curved = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);

    void listener() => _controller.value = tween.evaluate(curved);

    _anim
      ..reset()
      ..addListener(listener)
      ..forward().whenComplete(() {
        _anim.removeListener(listener);
        _isAnimatingFocus = false;
      });
  }

  void _focusBuilding(MapBuilding b, {bool animate = true}) {
    final targetScale = 2.5.clamp(_fitScale, 6.0);
    final target = _focusMatrix(b.center, targetScale);

    if (animate) {
      _animateTo(target, isFocus: true);
    } else {
      _isAnimatingFocus = true;
      _controller.value = target;
      _isAnimatingFocus = false;
    }
  }

  MapBuilding? _hitTest(List<MapBuilding> buildings, Offset scenePoint) {
    MapBuilding? best;
    var bestDist = double.infinity;

    for (final b in buildings) {
      bool isHit = false;

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
    final scenePoint = _controller.toScene(viewportPoint);
    final hit = _hitTest(buildings, scenePoint);
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
          // видимые здания с учётом фильтра (пустой фильтр = все)
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
                _fitScale = _viewport.shortestSide / kMapSize;

                if (!_isInitialized) {
                  _isInitialized = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final id = widget.focusBuildingId;
                    final target = all.where((b) => b.id == id).firstOrNull;
                    if (target != null) {
                      _focusBuilding(target, animate: false);
                    } else {
                      _controller.value = _fitMatrix();
                    }
                  });
                }
              }

              return Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (d) => _handleTap(buildings, d.localPosition),
                    onPanDown: (_) => _isAnimatingFocus = false,
                    child: ClipRect(
                      child: InteractiveViewer(
                        transformationController: _controller,
                        constrained: false,
                        minScale: 0.01,
                        maxScale: 50.0,
                        boundaryMargin: const EdgeInsets.all(100000.0),
                        onInteractionStart: (_) => _isAnimatingFocus = false,
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
                                      child: CustomPaint(
                                        painter: _PolygonHighlightPainter(
                                          polygon: b.polygon!,
                                          color: scheme.secondary
                                              .withValues(alpha: 0.45),
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
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Маркеры НЕ в IgnorePointer — они кликабельны.
                  // Пустые места слоя пропускают жесты к карте.
                  ValueListenableBuilder<Matrix4>(
                    valueListenable: _controller,
                    builder: (context, matrix, _) {
                      final currentScale = matrix.getMaxScaleOnAxis();
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
            onTap: () => _onBuildingTap(b), // тап по маркеру → bottom sheet
            child: SizedBox(
              width: 44, // увеличенная зона нажатия
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
