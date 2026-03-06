import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../services/penalty_service.dart';

class PenaltyBlindBoxOverlay extends StatefulWidget {
  const PenaltyBlindBoxOverlay({
    super.key,
    required this.result,
  });

  final PenaltyBlindBoxResult result;

  @override
  State<PenaltyBlindBoxOverlay> createState() => _PenaltyBlindBoxOverlayState();
}

class _PenaltyBlindBoxOverlayState extends State<PenaltyBlindBoxOverlay> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loserText = widget.result.losers.join('、');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t('penaltyBlindBoxTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('penaltyBlindBoxLosers', {'players': loserText}),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedIndex == null
                ? l10n.t('penaltyBlindBoxHint')
                : l10n.t('penaltyBlindBoxRevealed'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(widget.result.cards.length, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _BlindBoxCard(
                    index: index,
                    card: widget.result.cards[index],
                    revealed: _selectedIndex == index,
                    dimmed: _selectedIndex != null && _selectedIndex != index,
                    onTap: _selectedIndex == null
                        ? () => setState(() => _selectedIndex = index)
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BlindBoxCard extends StatelessWidget {
  const _BlindBoxCard({
    required this.index,
    required this.card,
    required this.revealed,
    required this.dimmed,
    this.onTap,
  });

  final int index;
  final PenaltyBlindBoxCard card;
  final bool revealed;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 420),
        tween: Tween<double>(begin: 0, end: revealed ? 1 : 0),
        builder: (context, value, _) {
          final showFront = dimmed || value >= 0.5;
          final turns = dimmed ? 0.0 : (showFront ? value - 1 : value);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(turns * math.pi),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: dimmed ? 0.45 : 1,
              child: showFront
                  ? _buildFront(context, keySuffix: 'front')
                  : _buildBack(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    return Container(
      key: Key('penalty-card-back-$index'),
      height: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF191919), Color(0xFF060606)],
        ),
        border: Border.all(color: const Color(0xFFB58A3C), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                AppColors.fingerCyan,
                AppColors.wheelOrange,
                AppColors.bombRed,
                AppColors.fingerCyan,
              ],
            ),
          ),
          child: SizedBox(width: 42, height: 42),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context, {required String keySuffix}) {
    final glow = switch (card.entry.level) {
      PenaltyLevel.level1 => AppColors.fingerCyan,
      PenaltyLevel.level2 => AppColors.wheelOrange,
      PenaltyLevel.level3 => AppColors.bombRed,
    };

    return Container(
      key: Key(
        dimmed ? 'penalty-card-dimmed-$index' : 'penalty-card-$keySuffix-$index',
      ),
      height: 172,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF5F1E8),
        border: Border.all(color: glow, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: glow.withAlpha(dimmed ? 50 : 130),
            blurRadius: dimmed ? 10 : 22,
            spreadRadius: dimmed ? 0 : 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.entry.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
