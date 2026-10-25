import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/features/tasks/providers/tasks_provider.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = dateOnly(DateTime.now());

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = dateOnly(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          IconButton(
            tooltip: 'Прототип карты',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push('/map-test'),
          ),
          IconButton(
            tooltip: 'Сегодня',
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TableCalendar<Task>(
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay,
              locale: locale,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
              rowHeight: 52,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => tasksOnDay(tasks, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = dateOnly(selected);
                  _focusedDay = focused;
                });
                context.push('/day/${dateToParam(selected)}');
              },
              onPageChanged: (focused) => _focusedDay = focused,
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 3,
                todayDecoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/task/new?date=${dateToParam(_selectedDay)}'),
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
    );
  }
}