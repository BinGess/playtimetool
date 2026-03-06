import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../styles/game_ui_style.dart';

enum GameStage { prepare, playing, result }

class GameStageStepper extends StatelessWidget {
  const GameStageStepper({
    super.key,
    required this.stage,
    required this.accentColor,
  });

  final GameStage stage;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    const labels = ['PREPARE', 'PLAY', 'RESULT'];
    final currentIndex = switch (stage) {
      GameStage.prepare => 0,
      GameStage.playing => 1,
      GameStage.result => 2,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final active = i == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active ? accentColor.withAlpha(40) : Colors.transparent,
              border: Border.all(
                color: active ? accentColor.withAlpha(150) : Colors.transparent,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: GameUiText.caption.fontSize,
                letterSpacing: 1.1,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }
}
