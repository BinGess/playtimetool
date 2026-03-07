import 'package:flutter/material.dart';

import '../styles/game_ui_style.dart';

class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.accentColor = Colors.white,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          GameIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack!,
            accentColor: accentColor,
          )
        else
          const SizedBox(width: 44, height: 44),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GameUiText.navTitle,
          ),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: trailing ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.accentColor = Colors.white,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withAlpha(110),
        side: BorderSide(color: accentColor.withAlpha(70)),
        padding: const EdgeInsets.all(10),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}
