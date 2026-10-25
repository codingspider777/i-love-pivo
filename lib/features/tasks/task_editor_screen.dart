import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';

/// Редактор задачи. Если [taskId] задан — редактирование, иначе создание.
/// (Привязка к карте будет добавлена отдельной задачей.)
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId, this.initialDate});

  final String? taskId;
  final DateTime? initialDate;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  Task? _existing;
  late DateTime _date;
  TimeOfDay? _time;
  TaskPriority _priority = TaskPriority.medium;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _existing = ref
          .read(tasksProvider)
          .where((t) => t.id == widget.taskId)
          .firstOrNull;
    }
    final task = _existing;
    _titleCtrl = TextEditingController(text: task?.title);
    _descCtrl = TextEditingController(text: task?.description);
    _date = task?.date ?? widget.initialDate ?? dateOnly(DateTime.now());
    _time = task?.time;
    _priority = task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: kFirstDay,
      lastDate: kLastDay,
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(tasksProvider.notifier);
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final existing = _existing;

    if (existing != null) {
      notifier.updateTask(existing.copyWith(
        title: title,
        description: description,
        date: _date,
        time: _time,
        clearTime: _time == null,
        priority: _priority,
      ));
    } else {
      notifier.addTask(Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        description: description,
        date: _date,
        time: _time,
        priority: _priority,
      ));
    }
    context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить задачу?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(tasksProvider.notifier).removeTask(widget.taskId!);
      context.pop();
    }
  }

  String? _validateDate() {
    // Для новых задач нельзя выбирать прошедшую дату.
    if (!_isEditing && _date.isBefore(dateOnly(DateTime.now()))) {
      return 'Дата не может быть в прошлом';
    }
    return null;
  }

  String? _validateTime() {
    final time = _time;
    if (time == null || _isEditing) return null;
    final now = DateTime.now();
    final isToday = _date == dateOnly(now);
    final timeMinutes = time.hour * 60 + time.minute;
    if (isToday && timeMinutes < now.hour * 60 + now.minute) {
      return 'Это время уже прошло';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && _existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Задача не найдена')),
      );
    }

    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Новая задача'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  hintText: 'Например: сдать лабораторную',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Введите название задачи';
                  if (text.length < 3) return 'Минимум 3 символа';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              // key меняется вместе со значением, чтобы поле обновило текст.
              TextFormField(
                key: ValueKey('date-${dateToParam(_date)}'),
                initialValue: formatLongDate(_date, locale),
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Дата *',
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (_) => _validateDate(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('time-${_time?.hour}-${_time?.minute}'),
                initialValue: _time?.format(context) ?? '',
                readOnly: true,
                onTap: _pickTime,
                decoration: InputDecoration(
                  labelText: 'Время (необязательно)',
                  prefixIcon: const Icon(Icons.schedule),
                  suffixIcon: _time == null
                      ? null
                      : IconButton(
                    tooltip: 'Убрать время',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _time = null),
                  ),
                ),
                validator: (_) => _validateTime(),
              ),
              const SizedBox(height: 20),
              Text('Приоритет', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskPriority>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in TaskPriority.values)
                      ButtonSegment(value: p, label: Text(p.label)),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (s) =>
                      setState(() => _priority = s.first),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
