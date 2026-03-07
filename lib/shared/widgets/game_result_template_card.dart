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
      borderRadius: BorderRadius.circular(24),
      borderColor: accentColor.withAlpha(120),
      tintColor:
          GameUiSurface.darkTone(accentColor, lightness: 0.16).withAlpha(205),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration:
                GameUiSurface.chip(accentColor: accentColor, selected: true),
            child: Text(
              resultTitle,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            resultText,
            style: GameUiText.bodyStrong.copyWith(
              fontSize: 18,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.glassBorder.withAlpha(180), height: 1),
          const SizedBox(height: 12),
          Text(
            penaltyTitle,
            style: GameUiText.eyebrow.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            penaltyText,
            style: GameUiText.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
