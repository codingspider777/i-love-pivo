import 'package:flutter/material.dart';
import 'package:salamanca/core/theme/app_theme.dart';

/// Общий чип для выбора приоритета и фильтров карты.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  /// Растянуть подпись на всю ширину (для ряда из Expanded).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;

    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: onSelected,
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHigh,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      avatar: icon == null ? null : Icon(icon, size: 18, color: fg),
      label: expand
          ? SizedBox(
              width: double.infinity,
              child: Text(label, textAlign: TextAlign.center),
            )
          : Text(label),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: fg),
    );
  }
}
