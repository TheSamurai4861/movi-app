import 'package:flutter/material.dart';

class MovieDetailSynopsisSection extends StatefulWidget {
  const MovieDetailSynopsisSection({super.key, required this.text});
  final String text;

  @override
  State<MovieDetailSynopsisSection> createState() =>
      _MovieDetailSynopsisSectionState();
}

class _MovieDetailSynopsisSectionState
    extends State<MovieDetailSynopsisSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final synopsisWidth = screenWidth - 40;
        return SizedBox(
          width: synopsisWidth,
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: _expanded
                      ? const BoxConstraints()
                      : const BoxConstraints(maxHeight: 90),
                  child: Stack(
                    children: [
                      Text(
                        widget.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                        softWrap: true,
                      ),
                      if (!_expanded)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              height: 41,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0xFF141414),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 102,
                height: 25,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Réduire' : 'Lire plus',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
