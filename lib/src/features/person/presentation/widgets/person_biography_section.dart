import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

/// Displays the biography with expand/collapse behavior.
class PersonBiographySection extends StatefulWidget {
  const PersonBiographySection({
    super.key,
    required this.biography,
  });

  final String biography;

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded
                          ? AppLocalizations.of(context)!.actionCollapse
                          : AppLocalizations.of(context)!.actionExpand,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
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