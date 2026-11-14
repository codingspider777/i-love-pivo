import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/widgets/priority_chips.dart';
import 'package:salamanca/shared/widgets/custom_text_field.dart';

/// Редактор задачи. Если [taskId] задан — редактирование, иначе создание.
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.taskId, this.initialDate, this.initialTitle});

  final String? taskId;
  final DateTime? initialDate;
  final String? initialTitle;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  Task? _existing;
  late DateTime _date;
  TimeOfDay? _time;
  TaskPriority _priority = TaskPriority.medium;
  bool _formatted = false;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final id = int.tryParse(widget.taskId!);
      _existing =
          ref.read(tasksProvider).where((t) => t.id == id).firstOrNull;
    }
    final task = _existing;
    _titleCtrl = TextEditingController(text: task?.title ?? widget.initialTitle);
    _descCtrl = TextEditingController(text: task?.description);
    _date = task?.date ?? widget.initialDate ?? dateOnly(DateTime.now());
    _time = task?.time;
    _priority = task?.priority ?? TaskPriority.medium;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // локаль и TimeOfDay.format требуют context — в initState нельзя
    if (!_formatted) {
      _formatted = true;
      _syncDate();
      _syncTime();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _syncDate() => _dateCtrl.text =
      formatLongDate(_date, Localizations.localeOf(context).toString());

  void _syncTime() => _timeCtrl.text = _time?.format(context) ?? '';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: kFirstDay,
      lastDate: kLastDay,
    );
    if (picked != null) {
      _date = dateOnly(picked);
      _syncDate();
      setState(() {});
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _time = picked;
      _syncTime();
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final actions = ref.read(tasksActionsProvider);
    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final existing = _existing;

    if (existing != null) {
      await actions.update(existing.copyWith(
        title: title,
        description: description,
        date: _date,
        time: _time,
        clearTime: _time == null,
        priority: _priority,
      ));
    } else {
      await actions.add(Task(
        id: 0,
        title: title,
        description: description,
        date: _date,
        time: _time,
        priority: _priority,
      ));
    }
    if (mounted) context.pop();
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
      await ref.read(tasksActionsProvider).remove(_existing!.id);
      if (mounted) context.pop();
    }
  }

  String? _validateDate(String? _) {
    // Для новых задач нельзя выбирать прошедшую дату.
    if (!_isEditing && _date.isBefore(dateOnly(DateTime.now()))) {
      return 'Дата не может быть в прошлом';
    }
    return null;
  }

  String? _validateTime(String? _) {
    final time = _time;
    if (time == null || _isEditing) return null;
    final now = DateTime.now();
    final isToday = _date == dateOnly(now);
    if (isToday && time.hour * 60 + time.minute < now.hour * 60 + now.minute) {
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: _titleCtrl,
                label: 'Название *',
                hint: 'Например: сдать лабораторную',
                maxLength: 100,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Введите название задачи';
                  if (text.length < 3) return 'Минимум 3 символа';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descCtrl,
                label: 'Описание',
                maxLength: 500,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _dateCtrl,
                label: 'Дата *',
                readOnly: true,
                onTap: _pickDate,
                prefixIcon: const Icon(Icons.event),
                validator: _validateDate,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _timeCtrl,
                label: 'Время (необязательно)',
                hint: 'Не задано',
                readOnly: true,
                onTap: _pickTime,
                prefixIcon: const Icon(Icons.schedule),
                suffixIcon: _time == null
                    ? null
                    : IconButton(
                        tooltip: 'Убрать время',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _time = null;
                          _syncTime();
                          setState(() {});
                        },
                      ),
                validator: _validateTime,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Приоритет',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              PriorityChips(
                value: _priority,
                onChanged: (p) => setState(() => _priority = p),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _save,
            child: const Text('Сохранить'),
          ),
        ),
      ),
    );
  }
}
