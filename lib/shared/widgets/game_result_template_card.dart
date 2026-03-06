import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../styles/game_ui_style.dart';
import 'glass_container.dart';

class GameResultTemplateCard extends StatelessWidget {
  const GameResultTemplateCard({
    super.key,
    required this.accentColor,
    required this.resultTitle,
    required this.resultText,
    required this.penaltyTitle,
    required this.penaltyText,
  });

  final Color accentColor;
  final String resultTitle;
  final String resultText;
  final String penaltyTitle;
  final String penaltyText;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(22),
      borderColor: accentColor.withAlpha(120),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resultTitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resultText,
            style: GameUiText.bodyStrong,
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.glassBorder.withAlpha(180), height: 1),
          const SizedBox(height: 12),
          Text(
            penaltyTitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            penaltyText,
            style: GameUiText.body.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
