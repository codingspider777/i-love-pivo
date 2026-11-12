import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salamanca/core/utils/date_utils.dart';
import 'package:salamanca/features/tasks/widgets/day_task_list.dart';

class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final day = dateOnly(date);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(formatDayTitle(day, locale)),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Новая задача',
            icon: const Icon(Icons.add),
            onPressed: () =>
                context.push('/task/new?date=${dateToParam(day)}'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DayTaskList(day: day),
    );
  }
}
