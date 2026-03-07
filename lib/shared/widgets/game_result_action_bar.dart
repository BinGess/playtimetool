import 'package:flutter/material.dart';
import '../styles/game_ui_style.dart';

class GameResultActionBar extends StatelessWidget {
  const GameResultActionBar({
    super.key,
    required this.accentColor,
    required this.primaryLabel,
    this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final Color accentColor;
  final String primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (secondaryLabel != null && onSecondaryTap != null) ...[
          SizedBox(
            width: double.infinity,
            height: GameUiSpacing.buttonHeight,
            child: OutlinedButton(
              onPressed: onSecondaryTap,
              style: GameUiSurface.secondaryButton(accentColor),
              child: Text(
                secondaryLabel!,
                style: GameUiText.buttonLabel,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: GameUiSpacing.buttonHeight + 4,
          child: ElevatedButton(
            onPressed: onPrimaryTap,
            style: GameUiSurface.primaryButton(accentColor),
            child: Text(primaryLabel),
          ),
        ),
      ],
    );
  }
}
