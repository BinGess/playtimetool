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
    final bgColor =
        selected ? accentColor.withAlpha(22) : Colors.black.withAlpha(96);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? accentColor : Colors.white.withAlpha(145),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GameUiText.bodyStrong,
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
