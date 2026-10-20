import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/topildi_theme.dart';

/// Labelled text field. [prefixText] renders a bold prefix with a divider
/// (used for `+998`). [hidden] styles it as the hidden-detail field.
class TInput extends StatefulWidget {
  const TInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.prefixText,
    this.leadingIcon,
    this.labelIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.hidden = false,
    this.textInputAction,
    this.autofocus = false,
  });

  /// Hidden-detail variant: lock label, dashed-feel container, private hint.
  const TInput.hidden({
    super.key,
    this.controller,
    this.hint = 'Masalan: ichida koʻk rangli bank kartasi bor',
    this.onChanged,
    this.error,
    this.maxLength,
  })  : label = 'Yashirin belgi',
        helper = 'Buni faqat siz koʻrasiz',
        prefixText = null,
        leadingIcon = null,
        labelIcon = Symbols.lock_rounded,
        maxLines = 4,
        minLines = 3,
        keyboardType = TextInputType.multiline,
        inputFormatters = null,
        hidden = true,
        textInputAction = null,
        autofocus = false;

  final String label;
  final TextEditingController? controller;
  final String? hint, helper, error, prefixText;
  final IconData? leadingIcon, labelIcon;
  final int? maxLines, minLines, maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool hidden;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  State<TInput> createState() => _TInputState();
}

class _TInputState extends State<TInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasError = widget.error != null;
    final labelColor = hasError ? cs.error : (_focus.hasFocus ? cs.primary : cs.onSurface);

    final prefix = widget.prefixText == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.prefixText!, style: text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(width: 1, height: 24, color: cs.outlineVariant),
              ],
            ),
          );

    final hiddenBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TRadius.md),
      borderSide: BorderSide(color: cs.outline),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (widget.labelIcon != null) ...[
              Icon(widget.labelIcon, size: 16, color: labelColor),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(widget.label, style: text.labelLarge!.copyWith(color: labelColor))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          autofocus: widget.autofocus,
          style: text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: prefix ?? (widget.leadingIcon != null ? Icon(widget.leadingIcon, size: 20) : null),
            prefixIconConstraints: prefix != null ? const BoxConstraints(minHeight: TSize.input) : null,
            fillColor: widget.hidden ? cs.surfaceContainerHigh : null,
            enabledBorder: widget.hidden ? hiddenBorder : null,
            border: widget.hidden ? hiddenBorder : null,
            errorText: widget.error,
            helperText: hasError ? null : widget.helper,
            helperStyle: text.bodySmall!.copyWith(fontSize: 13, color: cs.onSurfaceVariant),
            errorStyle: text.bodySmall!.copyWith(fontSize: 13, color: cs.error),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
