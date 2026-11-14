import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/settings/providers/settings_providers.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/quick_add/quick_add_parser.dart';
import 'package:salamanca/features/tasks/widgets/task_tile.dart';

/// Нижняя шторка быстрого добавления задачи с «умным» разбором текста.
class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.initialDate, this.initialTime});

  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  static Future<void> show(
    BuildContext context, {
    DateTime? date,
    TimeOfDay? time,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        builder: (_) => QuickAddSheet(initialDate: date, initialTime: time),
      );

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _ctrl = TextEditingController();
  late final DateTime _baseDate =
      dateOnly(widget.initialDate ?? DateTime.now());
  late DateTime _date = _baseDate;
  late TimeOfDay? _time = widget.initialTime;
  TaskPriority _priority = TaskPriority.medium;
  late int _catId = ref.read(categoriesProvider).first.id;
  String _title = '';

  // Если пользователь поправил поле вручную — парсер его больше не трогает.
  bool _mDate = false, _mTime = false, _mPrio = false, _mCat = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final p = QuickAddParser.parse(
      value,
      now: DateTime.now(),
      categories: ref.read(categoriesProvider),
    );
    setState(() {
      _title = p.title;
      if (!_mDate) _date = p.date ?? _baseDate;
      if (!_mTime) _time = p.time ?? widget.initialTime;
      if (!_mPrio) _priority = p.priority ?? TaskPriority.medium;
      if (!_mCat) {
        _catId = p.categoryId ?? ref.read(categoriesProvider).first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: kFirstDay,
      lastDate: kLastDay,
    );
    if (picked != null) {
      setState(() {
        _date = dateOnly(picked);
        _mDate = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _mTime = true;
      });
    }
  }

  Future<void> _save() async {
    if (_title.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final title = _title.length > 100 ? _title.substring(0, 100) : _title;
    await ref.read(tasksActionsProvider).add(Task(
          id: 0,
          title: title,
          date: _date,
          time: _time,
          priority: _priority,
          categoryId: _catId,
        ));
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Задача добавлена')));
  }

  String _dateLabel(String locale) {
    final today = dateOnly(DateTime.now());
    if (_date == today) return 'Сегодня';
    if (_date == DateTime(today.year, today.month, today.day + 1)) {
      return 'Завтра';
    }
    return DateFormat('E, d MMM', locale).format(_date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cats = ref.watch(categoriesProvider);
    final custom = ref.watch(priorityColorsProvider);
    final locale = Localizations.localeOf(context).toString();
    final cat = categoryOf(cats, _catId);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 12 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: _onChanged,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: 'Завтра в 10:00 сдать лабу',
              suffixIcon: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton.filled(
                  tooltip: 'Добавить',
                  onPressed: _title.isEmpty ? null : _save,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(_dateLabel(locale)),
                  onPressed: _pickDate,
                ),
                const SizedBox(width: 8),
                InputChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(_time?.format(context) ?? 'Время'),
                  onPressed: _pickTime,
                  onDeleted: _time == null
                      ? null
                      : () => setState(() {
                            _time = null;
                            _mTime = true;
                          }),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(Icons.flag,
                      size: 18, color: priorityColor(scheme, _priority, custom)),
                  label: Text(_priority.label),
                  onPressed: () => setState(() {
                    _priority = TaskPriority
                        .values[(_priority.index + 1) % TaskPriority.values.length];
                    _mPrio = true;
                  }),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  initialValue: _catId,
                  onSelected: (id) => setState(() {
                    _catId = id;
                    _mCat = true;
                  }),
                  itemBuilder: (_) => [
                    for (final c in cats)
                      PopupMenuItem(
                        value: c.id,
                        child: Row(children: [
                          Icon(c.icon, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ]),
                      ),
                  ],
                  child: Chip(
                    avatar: Icon(cat.icon, size: 18, color: cat.color),
                    label: Text(cat.name),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Например: «в пятницу в 18:30 созвон #работа !высокий»',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
