import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/settings/providers/settings_providers.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/quick_add/quick_add_sheet.dart';

DateTime _mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));
DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

const double _timeCol = 40;
const double _rowMin = 60;

/// Недельный вид: 7 колонок × часовые слоты. Задачи можно перетаскивать
/// (долгое нажатие) между днями и часами; строка «Весь день» — задачи без времени.
class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  late DateTime _weekStart =
      _mondayOf(widget.initialDate ?? dateOnly(DateTime.now()));
  int _dir = 1;

  final _scroll = ScrollController(initialScrollOffset: 7 * _rowMin);
  final _gridKey = GlobalKey();
  Timer? _autoScroll;
  Offset? _dragPos;

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _shift(int weeks) => setState(() {
        _dir = weeks.sign;
        _weekStart = _addDays(_weekStart, 7 * weeks);
      });

  void _goToday() {
    final ws = _mondayOf(dateOnly(DateTime.now()));
    if (ws == _weekStart) return;
    setState(() {
      _dir = ws.isAfter(_weekStart) ? 1 : -1;
      _weekStart = ws;
    });
  }

  // ---- автопрокрутка во время перетаскивания ----
  void _dragStarted() {
    _autoScroll?.cancel();
    _autoScroll = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final g = _dragPos;
      final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (g == null ||
          box == null ||
          !box.attached ||
          _scroll.positions.isEmpty) {
        return;
      }
      final y = box.globalToLocal(g).dy;
      const edge = 64.0;
      var delta = 0.0;
      if (y < edge) {
        delta = -(edge - y) / edge * 12;
      } else if (y > box.size.height - edge) {
        delta = (y - (box.size.height - edge)) / edge * 12;
      }
      if (delta == 0) return;
      final pos = _scroll.positions.last;
      pos.jumpTo((pos.pixels + delta)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent));
    });
  }

  void _dragEnded() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _dragPos = null;
  }

  Future<void> _drop(Task t, DateTime day, int? hour) async {
    final newTime = hour == null
        ? null
        : TimeOfDay(
            hour: hour, minute: t.time?.hour == hour ? t.time!.minute : 0);
    if (dateOnly(t.date) == day && t.time == newTime) return;

    final actions = ref.read(tasksActionsProvider);
    await actions.update(
        t.copyWith(date: day, time: newTime, clearTime: newTime == null));
    if (!mounted) return;

    final locale = Localizations.localeOf(context).toString();
    final when = DateFormat('E, d MMM', locale).format(day) +
        (newTime == null ? '' : ' · ${newTime.format(context)}');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Перенесено: $when'),
        action: SnackBarAction(
            label: 'Отменить', onPressed: () => actions.update(t)),
      ));
  }

  String _rangeTitle(String locale) {
    final a = _weekStart;
    final b = _addDays(a, 6);
    final df = DateFormat('d MMM', locale);
    return '${df.format(a)} – ${df.format(b)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(tasksProvider);
    final cats = ref.watch(categoriesProvider);
    final locale = Localizations.localeOf(context).toString();
    final days = [for (var i = 0; i < 7; i++) _addDays(_weekStart, i)];
    final perDay = [for (final d in days) tasksOnDay(all, d)];
    final empty = perDay.every((l) => l.isEmpty);
    final today = dateOnly(DateTime.now());
    final fabDate = days.contains(today) ? today : days.first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Неделя'),
            Text(_rangeTitle(locale),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Предыдущая неделя',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shift(-1),
          ),
          IconButton(
            tooltip: 'Сегодня',
            icon: const Icon(Icons.today),
            onPressed: _goToday,
          ),
          IconButton(
            tooltip: 'Следующая неделя',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shift(1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Быстрая задача',
        onPressed: () => QuickAddSheet.show(context, date: fabDate),
        child: const Icon(Icons.bolt_rounded),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v < -400) {
            _shift(1);
          } else if (v > 400) {
            _shift(-1);
          }
        },
        child: Stack(
          children: [
            SizedBox.expand(
              key: _gridKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey<DateTime>(_weekStart);
                  final begin = Offset(_dir * (incoming ? 0.25 : -0.25), 0);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween(begin: begin, end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: _WeekGrid(
                  key: ValueKey<DateTime>(_weekStart),
                  days: days,
                  tasks: perDay,
                  categories: cats,
                  controller: _scroll,
                  locale: locale,
                  onDrop: _drop,
                  onAdd: (day, hour) => QuickAddSheet.show(
                    context,
                    date: day,
                    time: hour == null
                        ? null
                        : TimeOfDay(hour: hour, minute: 0),
                  ),
                  onDragStarted: _dragStarted,
                  onDragUpdate: (p) => _dragPos = p,
                  onDragEnd: _dragEnded,
                ),
              ),
            ),
            if (empty)
              const Positioned(
                top: 150,
                left: 24,
                right: 24,
                child: IgnorePointer(child: _WeekEmptyHint()),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekEmptyHint extends StatelessWidget {
  const _WeekEmptyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Column(
        children: [
          Icon(Icons.event_available, size: 40, color: scheme.secondary),
          const SizedBox(height: 8),
          Text('На этой неделе задач нет', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Нажмите на ячейку или на кнопку быстрого добавления',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    super.key,
    required this.days,
    required this.tasks,
    required this.categories,
    required this.controller,
    required this.locale,
    required this.onDrop,
    required this.onAdd,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final List<DateTime> days;
  final List<List<Task>> tasks;
  final List<TaskCategory> categories;
  final ScrollController controller;
  final String locale;
  final Future<void> Function(Task, DateTime, int?) onDrop;
  final void Function(DateTime, int?) onAdd;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  Widget _row(BuildContext context, int? hour) {
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(DateTime.now());
    final label = hour == null
        ? 'Весь\nдень'
        : '${hour.toString().padLeft(2, '0')}:00';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeCol,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _Cell(
                minHeight: hour == null ? 44 : _rowMin,
                isToday: days[i] == today,
                tasks: tasks[i]
                    .where((t) =>
                        hour == null ? t.time == null : t.time?.hour == hour)
                    .toList(),
                categories: categories,
                onTap: () => onAdd(days[i], hour),
                onDrop: (t) => onDrop(t, days[i], hour),
                onDragStarted: onDragStarted,
                onDragUpdate: onDragUpdate,
                onDragEnd: onDragEnd,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = dateOnly(DateTime.now());

    final header = Row(
      children: [
        const SizedBox(width: _timeCol),
        for (final d in days)
          Expanded(
            child: InkWell(
              onTap: () => context.push('/day/${dateToParam(d)}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E', locale).format(d).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: d.weekday >= 6
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: d == today ? scheme.primary : null,
                      ),
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: d == today ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const Divider(height: 1),
        _row(context, null),
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey('week_scroll'),
            controller: controller,
            child: Column(children: [
              for (var h = 0; h < 24; h++) _row(context, h),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.minHeight,
    required this.isToday,
    required this.tasks,
    required this.categories,
    required this.onTap,
    required this.onDrop,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final double minHeight;
  final bool isToday;
  final List<Task> tasks;
  final List<TaskCategory> categories;
  final VoidCallback onTap;
  final ValueChanged<Task> onDrop;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant.withValues(alpha: 0.6);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidate, _) => InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: candidate.isNotEmpty
                ? scheme.primary.withValues(alpha: 0.16)
                : (isToday ? scheme.primary.withValues(alpha: 0.05) : null),
            border: Border(
              left: BorderSide(color: line),
              top: BorderSide(color: line),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _DraggableChip(
                    task: t,
                    color: categoryOf(categories, t.categoryId).color,
                    onDragStarted: onDragStarted,
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraggableChip extends StatelessWidget {
  const _DraggableChip({
    required this.task,
    required this.color,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Task task;
  final Color color;
  final VoidCallback onDragStarted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final body = _ChipBody(task: task, color: color);
    return LongPressDraggable<Task>(
      data: task,
      dragAnchorStrategy: (draggable, context, position) =>
          const Offset(60, 18),
      onDragStarted: onDragStarted,
      onDragUpdate: (d) => onDragUpdate(d.globalPosition),
      onDragEnd: (_) => onDragEnd(),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: SizedBox(width: 120, child: body),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: body),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/task/${task.id}'),
        child: body,
      ),
    );
  }
}

class _ChipBody extends StatelessWidget {
  const _ChipBody({required this.task, required this.color});
  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 2, 3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            color.withValues(alpha: 0.2), scheme.surfaceContainerLow),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          height: 1.15,
          fontWeight: FontWeight.w600,
          decoration: task.isDone ? TextDecoration.lineThrough : null,
          color: task.isDone ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
}
