import 'package:flutter/material.dart';

import '../styles/game_ui_style.dart';

class DifficultyOptionCard extends StatelessWidget {
  const DifficultyOptionCard({
    super.key,
    required this.title,
    this.hint,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String? hint;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accentColor : Colors.white.withAlpha(55);
    final secondaryColor = GameUiSurface.shiftHue(accentColor, by: 24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      accentColor.withAlpha(36),
                      secondaryColor.withAlpha(18),
                      Colors.black.withAlpha(132),
                    ]
                  : [
                      Colors.white.withAlpha(8),
                      Colors.black.withAlpha(118),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withAlpha(28),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: GameUiSurface.chip(
                  accentColor: accentColor,
                  selected: selected,
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  color: selected ? accentColor : Colors.white.withAlpha(145),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GameUiText.bodyStrong.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    if (hint != null && hint!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        style: GameUiText.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
