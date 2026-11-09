import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:salamanca/features/tasks/widgets/day_task_list.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = dateOnly(DateTime.now());

  void _goToToday() => setState(() {
        _focusedDay = DateTime.now();
        _selectedDay = dateOnly(DateTime.now());
      });

  void _addTask() =>
      context.push('/task/new?date=${dateToParam(_selectedDay)}');

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          IconButton(
            tooltip: 'Карта кампуса',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push('/map'),
          ),
          IconButton(
            tooltip: 'Сегодня',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
          IconButton.filledTonal(
            tooltip: 'Новая задача',
            icon: const Icon(Icons.add),
            onPressed: _addTask,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: TableCalendar<Task>(
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay,
                  locale: locale,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Месяц',
                  },
                  rowHeight: 44,
                  daysOfWeekHeight: 28,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => tasksOnDay(tasks, day),
                  onDaySelected: (selected, focused) => setState(() {
                    _selectedDay = dateOnly(selected);
                    _focusedDay = focused;
                  }),
                  onPageChanged: (focused) => _focusedDay = focused,
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    headerPadding: const EdgeInsets.symmetric(vertical: 4),
                    titleTextStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                    titleTextFormatter: (date, loc) =>
                        toBeginningOfSentenceCase(
                            DateFormat('LLLL yyyy', loc).format(date))!,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                    weekendStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.error.withValues(alpha: 0.85),
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(4),
                    markersMaxCount: 3,
                    markerSize: 5,
                    defaultTextStyle: TextStyle(color: scheme.onSurface),
                    weekendTextStyle: TextStyle(color: scheme.error),
                    todayTextStyle: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedTextStyle: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    todayDecoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: scheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                toBeginningOfSentenceCase(
                    formatDayTitle(_selectedDay, locale))!,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(child: DayTaskList(day: _selectedDay)),
        ],
      ),
    );
  }
}
