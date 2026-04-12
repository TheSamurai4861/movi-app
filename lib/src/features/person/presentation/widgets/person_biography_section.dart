import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';

/// Displays the biography with expand/collapse behavior.
class PersonBiographySection extends StatefulWidget {
  const PersonBiographySection({
    super.key,
    required this.biography,
    this.expandFocusNode,
    this.onExpandKeyEvent,
  });

  final String biography;
  final FocusNode? expandFocusNode;
  final KeyEventResult Function(KeyEvent event)? onExpandKeyEvent;

  @override
  State<PersonBiographySection> createState() => _PersonBiographySectionState();
}

class _PersonBiographySectionState extends State<PersonBiographySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final needsExpansion = _needsExpansion(widget.biography, maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.personBiographyTitle,
              style:
                  Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ) ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  widget.biography,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (needsExpansion)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Center(
                  child: IntrinsicWidth(
                    child: Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) =>
                          widget.onExpandKeyEvent?.call(event) ??
                          KeyEventResult.ignored,
                      child: MoviFocusableAction(
                        behavior: HitTestBehavior.deferToChild,
                        focusNode: widget.expandFocusNode,
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        semanticLabel: _isExpanded
                            ? AppLocalizations.of(context)!.actionCollapse
                            : AppLocalizations.of(context)!.actionExpand,
                        builder: (context, state) {
                          return MoviFocusFrame(
                            scale: state.focused ? 1.04 : 1,
                            borderRadius: BorderRadius.circular(999),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            borderColor: state.focused
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderWidth: 2,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded
                                      ? AppLocalizations.of(
                                          context,
                                        )!.actionCollapse
                                      : AppLocalizations.of(
                                          context,
                                        )!.actionExpand,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _needsExpansion(String text, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: const TextSpan(style: TextStyle(fontSize: 16), text: ''),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    painter.text = TextSpan(text: text, style: const TextStyle(fontSize: 16));
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }
}
