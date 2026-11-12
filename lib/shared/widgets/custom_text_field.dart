import 'package:flutter/material.dart';

/// Filled-поле без рамок. Счётчик символов — внутри поля, справа внизу.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final AutovalidateMode autovalidateMode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController();
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    // чтобы программные изменения текста (выбор даты/времени)
    // тоже перевалидировали поле
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() => _fieldKey.currentState?.didChange(_ctrl.text);

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showCounter = widget.maxLength != null;

    return FormField<String>(
      key: _fieldKey,
      initialValue: _ctrl.text,
      autovalidateMode: widget.autovalidateMode,
      validator: (_) => widget.validator?.call(_ctrl.text),
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  widget.label!,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            Stack(
              children: [
                TextField(
                  controller: _ctrl,
                  readOnly: widget.readOnly,
                  showCursor: !widget.readOnly,
                  enableInteractiveSelection: !widget.readOnly,
                  onTap: widget.onTap,
                  minLines: widget.minLines,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.suffixIcon,
                    counterText: '', // стандартный счётчик скрыт
                    fillColor: state.hasError
                        ? scheme.errorContainer.withValues(alpha: 0.35)
                        : null,
                    contentPadding: EdgeInsets.fromLTRB(
                        16, 14, 16, showCounter ? 28 : 14),
                  ),
                ),
                if (showCounter)
                  Positioned(
                    right: 12,
                    bottom: 8,
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: _ctrl,
                        builder: (_, _) => Text(
                          '${_ctrl.text.length}/${widget.maxLength}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  state.errorText ?? '',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
