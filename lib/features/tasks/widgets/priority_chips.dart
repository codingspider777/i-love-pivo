import 'package:flutter/material.dart';
import 'package:salamanca/data/models/task.dart';
import 'package:salamanca/shared/widgets/app_choice_chip.dart';

class PriorityChips extends StatelessWidget {
  const PriorityChips(
      {super.key, required this.value, required this.onChanged});

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, p) in TaskPriority.values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AppChoiceChip(
              label: p.label,
              expand: true,
              selected: p == value,
              onSelected: (_) => onChanged(p),
            ),
          ),
        ],
      ],
    );
  }
}
