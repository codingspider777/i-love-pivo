import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:salamanca/features/map/models/map_building.dart';

/// Размер SVG-карты (должен совпадать с viewBox в main_map_light/dark.svg).
const double kMapSize = 1500;

/// ВЫКЛЮЧИЛ ОТЛАДКУ, чтобы красные рамки не мешали смотреть названия.
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

  // Хелпер для иконок маркеров
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'dormitory':
        return Icons.bed;
      case 'sport':
        return Icons.sports_soccer;
      case 'food':
        return Icons.restaurant;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.school; // academic
    }
  }

  // Хелпер для цветов маркеров
  Color _getColorForCategory(String category) {
    switch (category) {
      case 'dormitory':
        return Colors.orange;
      case 'sport':
        return Colors.green;
      case 'food':
        return Colors.redAccent;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.blue; // academic
    }
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

                      // 1. Невидимые кнопки для обработки нажатий
                      for (final b in buildings)
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
                            ),
                          ),
                        ),

                      // 2. Иконки и Текст поверх зданий
                      for (final b in buildings) ...[
                        // Иконка категории (висящая над текстом)
                        Positioned(
                          left: b.center.dx - 12,
                          top: b.center.dy - 35,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black87 : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getIconForCategory(b.category),
                                size: 14, // Размер иконки
                                color: _getColorForCategory(b.category),
                              ),
                            ),
                          ),
                        ),
                        
                        // Текст
                        Positioned(
                          left: b.center.dx,
                          top: b.center.dy,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: IgnorePointer(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 130),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.black.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  b.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: b.width < 40 ? 9 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
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

// 📌 КРАСИВЫЙ BOTTOM SHEET
class _BuildingSheet extends StatelessWidget {
  const _BuildingSheet({required this.building});

  final MapBuilding building;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Получаем иконку для заголовка карточки
    IconData getIcon(String cat) {
      switch (cat) {
        case 'dormitory':
          return Icons.bed;
        case 'sport':
          return Icons.sports_soccer;
        case 'food':
          return Icons.restaurant;
        case 'admin':
          return Icons.admin_panel_settings;
        default:
          return Icons.school;
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Полоска для свайпа вниз (drag handle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Заголовок с иконкой
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    getIcon(building.category),
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    building.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Описание
            Text(
              building.description.isEmpty
                  ? 'Описание пока не добавлено'
                  : building.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Кнопка действия (пока пустая)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  // TODO: В будущем здесь будет создание задачи с привязкой к зданию
                },
                child: const Text('Создать задачу здесь'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}