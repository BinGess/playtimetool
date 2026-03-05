import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/penalty_models.dart';

typedef PenaltyLabelBuilder = String Function(PenaltyItem item);

Future<PenaltyItem?> showPenaltyPickerSheet(
  BuildContext context, {
  required List<PenaltyItem> candidates,
  required PenaltyItem selected,
  PenaltyLabelBuilder? labelBuilder,
}) {
  return showModalBottomSheet<PenaltyItem>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PenaltyPickerSheet(
      candidates: candidates,
      selected: selected,
      labelBuilder: labelBuilder,
    ),
  );
}

class PenaltyPickerSheet extends StatefulWidget {
  const PenaltyPickerSheet({
    super.key,
    required this.candidates,
    required this.selected,
    this.labelBuilder,
    this.random,
  });

  final List<PenaltyItem> candidates;
  final PenaltyItem selected;
  final PenaltyLabelBuilder? labelBuilder;
  final Random? random;

  @override
  State<PenaltyPickerSheet> createState() => _PenaltyPickerSheetState();
}

class _PenaltyPickerSheetState extends State<PenaltyPickerSheet> {
  late PenaltyItem _selected;
  bool _showList = false;

  Random get _random => widget.random ?? Random();

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  String _label(PenaltyItem item) {
    if (widget.labelBuilder != null) return widget.labelBuilder!(item);
    return item.textKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.t('penaltyLabel'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surfaceVariant,
                ),
                child: Text(
                  _label(_selected),
                  key: const Key('penalty-selected-item'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('penalty-random-button'),
                      onPressed: () {
                        final item = widget.candidates[
                            _random.nextInt(widget.candidates.length)];
                        setState(() => _selected = item);
                      },
                      child: Text(l10n.t('penaltyRandom')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('penalty-choose-button'),
                      onPressed: () => setState(() => _showList = !_showList),
                      child: Text(l10n.t('penaltyChoose')),
                    ),
                  ),
                ],
              ),
              if (_showList) ...[
                const SizedBox(height: 10),
                SizedBox(
                  key: const Key('penalty-item-list'),
                  height: 220,
                  child: ListView.builder(
                    itemCount: widget.candidates.length,
                    itemBuilder: (context, index) {
                      final item = widget.candidates[index];
                      final active = item.id == _selected.id;
                      return ListTile(
                        key: Key('penalty-item-${item.id}'),
                        title: Text(
                          _label(item),
                          style: TextStyle(
                            color: active
                                ? AppColors.fingerCyan
                                : AppColors.textPrimary,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        trailing: active
                            ? const Icon(
                                Icons.check,
                                color: AppColors.fingerCyan,
                                size: 18,
                              )
                            : null,
                        onTap: () => setState(() => _selected = item),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: Text(l10n.t('penaltyApply')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
