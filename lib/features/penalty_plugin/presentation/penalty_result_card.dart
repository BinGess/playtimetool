import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PenaltyResultCard extends StatelessWidget {
  const PenaltyResultCard({
    super.key,
    required this.title,
    required this.value,
    required this.onOpenPicker,
  });

  final String title;
  final String value;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            key: const Key('penalty-result-card-value'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              key: const Key('open-penalty-picker'),
              onPressed: onOpenPicker,
              child: const Text('?'),
            ),
          ),
        ],
      ),
    );
  }
}
