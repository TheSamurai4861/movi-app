import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/focus/widgets/app_directional_focus_wrapper.dart';

class AppLabeledTextField extends StatelessWidget {
  const AppLabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.helpText,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.counterText,
    this.obscureText = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.nextDownFocus,
    this.nextUpFocus,
    this.nextLeftFocus,
    this.nextRightFocus,
    this.blockUp = false,
    this.blockDown = false,
    this.blockLeft = true,
    this.blockRight = true,
    this.verticalAlignment = 0.4,
    this.enableFocusWrapper = false,
    this.showHelpTextWhenError = false,
    this.decoration,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? helpText;
  final String? errorText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? counterText;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? nextDownFocus;
  final FocusNode? nextUpFocus;
  final FocusNode? nextLeftFocus;
  final FocusNode? nextRightFocus;
  final bool blockUp;
  final bool blockDown;
  final bool blockLeft;
  final bool blockRight;
  final double verticalAlignment;
  final bool enableFocusWrapper;
  final bool showHelpTextWhenError;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShowHelpText =
        helpText != null && (showHelpTextWhenError || errorText == null);

    Widget field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        hintText: hintText,
        errorText: errorText,
        counterText: counterText,
      ),
    );

    if (enableFocusWrapper) {
      field = AppDirectionalFocusWrapper(
        verticalAlignment: verticalAlignment,
        nextUpFocus: nextUpFocus,
        nextDownFocus: nextDownFocus,
        nextLeftFocus: nextLeftFocus,
        nextRightFocus: nextRightFocus,
        blockUp: blockUp,
        blockDown: blockDown,
        blockLeft: blockLeft,
        blockRight: blockRight,
        child: field,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        field,
        if (shouldShowHelpText) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Text(
              helpText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ],
    );
  }
}