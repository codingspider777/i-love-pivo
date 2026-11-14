import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:salamanca/core/theme/app_theme.dart';

/// Размеры виджета Android: Small (2×2), Medium (4×2), Large (4×4).
enum WidgetSize {
  small('widget_small', Size(160, 160),
      'com.example.salamanca.TasksWidgetSmall', 0),
  medium('widget_medium', Size(320, 160),
      'com.example.salamanca.TasksWidgetMedium', 3),
  large('widget_large', Size(320, 320),
      'com.example.salamanca.TasksWidgetLarge', 7);

  const WidgetSize(
      this.prefKey, this.logicalSize, this.androidProvider, this.maxItems);

  /// Ключ в SharedPreferences, куда home_widget кладёт путь к PNG.
  final String prefKey;
  final Size logicalSize;
  final String androidProvider;
  final int maxItems;
}

class WidgetItem {
  const WidgetItem({
    required this.title,
    required this.color,
    this.time,
    this.done = false,
  });
  final String title;
  final Color color;
  final String? time;
  final bool done;
}

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.date,
    required this.items,
    required this.open,
    required this.total,
  });
  final DateTime date;
  final List<WidgetItem> items;
  final int open;
  final int total;
}

String _plural(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

/// Flutter-вёрстка виджета. Рендерится в PNG через
/// HomeWidget.renderFlutterWidget, поэтому нужны свои Directionality/Theme.
class TasksWidgetCard extends StatelessWidget {
  const TasksWidgetCard({
    super.key,
    required this.snapshot,
    required this.size,
    required this.dark,
  });

  final WidgetSnapshot snapshot;
  final WidgetSize size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF111A3A) : Colors.white;
    final fg = dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFF9AA5C0) : const Color(0xFF64748B);
    final accent = dark ? AppColors.primaryOnDark : AppColors.primary;

    final body = size == WidgetSize.small
        ? _small(fg, muted, accent)
        : _list(fg, muted, accent);

    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: dark ? AppTheme.dark : AppTheme.light,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox.fromSize(
              size: size.logicalSize,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _small(Color fg, Color muted, Color accent) {
    final s = snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('EEEE', 'ru').format(s.date),
            style: TextStyle(fontSize: 11, color: muted)),
        Text(DateFormat('d MMMM', 'ru').format(s.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
        const Spacer(),
        Text('${s.open}',
            style: TextStyle(
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.w800,
                color: accent)),
        const SizedBox(height: 2),
        Text(
          s.total == 0
              ? 'задач нет'
              : '${_plural(s.open, 'задача', 'задачи', 'задач')} осталось',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }

  Widget _list(Color fg, Color muted, Color accent) {
    final s = snapshot;
    final items = s.items.take(size.maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('d MMMM', 'ru').format(s.date),
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                  Text(DateFormat('EEEE', 'ru').format(s.date),
                      style: TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.total == 0 ? 'Свободно' : 'Осталось ${s.open}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('На сегодня задач нет',
                      style: TextStyle(fontSize: 13, color: muted)),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final it in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: it.color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 38,
                              child: Text(it.time ?? '—',
                                  style:
                                      TextStyle(fontSize: 11, color: muted)),
                            ),
                            Expanded(
                              child: Text(
                                it.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: it.done ? muted : fg,
                                  decoration: it.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
