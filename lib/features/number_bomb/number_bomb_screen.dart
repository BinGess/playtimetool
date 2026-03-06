import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'models/bomb_state.dart';
import 'providers/number_bomb_provider.dart';

class NumberBombScreen extends ConsumerStatefulWidget {
  const NumberBombScreen({super.key});

  @override
  ConsumerState<NumberBombScreen> createState() => _NumberBombScreenState();
}

class _NumberBombScreenState extends ConsumerState<NumberBombScreen>
    with TickerProviderStateMixin {
  final Random _penaltyRandom = Random();
  late AnimationController _bombPulseController;
  late AnimationController _explosionController;
  late Animation<double> _bombPulse;
  late Animation<double> _explosionAnim;
  bool _showHelpButton = false;
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  @override
  void initState() {
    super.initState();

    _bombPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bombPulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bombPulseController, curve: Curves.easeInOut),
    );

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _explosionAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_explosionController);
    _initGameHelp();
  }

  @override
  void dispose() {
    _bombPulseController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(numberBombProvider);
    final notifier = ref.read(numberBombProvider.notifier);

    ref.listen(numberBombProvider, (prev, next) {
      if (next.lastGuessInvalid && !(prev?.lastGuessInvalid ?? false)) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.invalidRangeHint(next.minRange, next.maxRange),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.bombRed.withAlpha(220),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      if (next.phase == BombPhase.explosion &&
          prev?.phase != BombPhase.explosion) {
        final loserLabel = next.loserPlayerIndex == null
            ? AppLocalizations.of(context).t('penaltyCurrentPlayerLabel')
            : AppLocalizations.of(context)
                .playerLabel(next.loserPlayerIndex! + 1);
        _blindBoxResult = PenaltyService.resolveBlindBox(
          l10n: AppLocalizations.of(context),
          random: _penaltyRandom,
          preset: _penaltyPreset,
          losers: <String>[loserLabel],
        );
        _explosionController.reset();
        _explosionController.forward();
      }
    });

    final bgColor = Color.lerp(
      AppColors.bombBlueDark,
      AppColors.bombRedDark,
      state.pressureRatio,
    )!;

    if (state.phase == BombPhase.explosion &&
        !_explosionController.isAnimating &&
        _explosionController.value == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(numberBombProvider).phase == BombPhase.explosion) {
          _explosionController.forward();
        }
      });
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _explosionAnim,
        builder: (_, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            color: bgColor,
            child: child,
          );
        },
        child: Stack(
          children: [
            const Web3GameBackground(
              accentColor: AppColors.bombRed,
              secondaryColor: AppColors.fingerCyan,
              overlayOpacity: 0.38,
            ),
            // Red breathing overlay (pressure escalation)
            if (state.phase == BombPhase.playing)
              AnimatedBuilder(
                animation: _bombPulse,
                builder: (_, __) => Opacity(
                  opacity: state.pressureRatio * 0.15 * (1 - _bombPulse.value),
                  child: Container(color: AppColors.bombRed),
                ),
              ),

            SafeArea(
              child: state.phase == BombPhase.setup
                  ? _SetupView(
                      onStart: notifier.startGame,
                      l10n: AppLocalizations.of(context),
                      penaltyPreset: _penaltyPreset,
                      onPenaltyPresetChanged: (preset) {
                        setState(() => _penaltyPreset = preset);
                      },
                    )
                  : state.phase == BombPhase.playing
                      ? _PlayingView(
                          state: state,
                          notifier: notifier,
                          bombPulse: _bombPulse,
                          l10n: AppLocalizations.of(context),
                        )
                      : const SizedBox.shrink(),
            ),

            // Explosion overlay
            if (state.phase == BombPhase.explosion)
              _ExplosionOverlay(
                state: state,
                anim: _explosionAnim,
                blindBoxResult: _blindBoxResult,
                onReset: notifier.reset,
                l10n: AppLocalizations.of(context),
              ),

            // Back edge swipe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 200) context.pop();
                },
              ),
            ),

            if (_showHelpButton)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 12,
                child: GameHelpButton(
                  onTap: _showGameHelp,
                  iconColor: AppColors.textSecondary,
                  borderColor: AppColors.textDim,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'number_bomb',
        gameTitle: l10n.numberBomb,
        helpBody: l10n.t('helpNumberBombBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.numberBomb,
      helpBody: l10n.t('helpNumberBombBody'),
    );
  }
}

class _SetupView extends StatefulWidget {
  const _SetupView({
    required this.onStart,
    required this.l10n,
    required this.penaltyPreset,
    required this.onPenaltyPresetChanged,
  });

  final void Function({int min, int max, int playerCount}) onStart;
  final AppLocalizations l10n;
  final PenaltyPreset penaltyPreset;
  final ValueChanged<PenaltyPreset> onPenaltyPresetChanged;

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  // Preset options: (index for label, min, max)
  static const _presets = [
    (0, 1, 50),
    (1, 1, 100),
    (2, 1, 500),
    (3, 0, 0),
  ];

  int _selectedPreset = 1; // default: 1–100
  int _playerCount = 2;
  int _customMin = 1;
  int _customMax = 200;

  bool get _isCustom => _selectedPreset == 3;

  int get _effectiveMin =>
      _isCustom ? _customMin : _presets[_selectedPreset].$2;
  int get _effectiveMax =>
      _isCustom ? _customMax : _presets[_selectedPreset].$3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GameUiSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  widget.l10n.numberBombTitle,
                  textAlign: TextAlign.center,
                  style: GameUiText.navTitle,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: GameUiSpacing.blockGap),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: widget.l10n.t('numberBombPrepPlayersTitle'),
                    subtitle: widget.l10n.t('numberBombPrepPlayersHint'),
                    trailing: _buildStatusChip(
                      widget.l10n.playersCount(_playerCount),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 88,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.bombRed.withAlpha(110),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.bombRed.withAlpha(42),
                                    const Color(0x14110B0B),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$_playerCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.l10n.t('numberBombPrepPlayersTitle'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFB3B3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.l10n.t('numberBombPrepHint'),
                                style: GameUiText.body,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            inactiveTrackColor: Colors.white12,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            key: const Key('number-bomb-player-slider'),
                            value: _playerCount.toDouble(),
                            min: 2,
                            max: 8,
                            divisions: 6,
                            activeColor: AppColors.bombRed,
                            onChanged: (value) =>
                                setState(() => _playerCount = value.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: widget.l10n.t('numberBombPrepRangeTitle'),
                    subtitle: widget.l10n.t('numberBombPrepRangeHint'),
                    trailing: _buildStatusChip(
                      '$_effectiveMin — $_effectiveMax',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_presets.length, (i) {
                            final active = i == _selectedPreset;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedPreset = i);
                                HapticService.lightImpact();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.bombRed.withAlpha(210)
                                        : AppColors.textDim,
                                    width: active ? 1.5 : 1,
                                  ),
                                  color: active
                                      ? AppColors.bombRed.withAlpha(25)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  widget.l10n.rangePresetLabel(_presets[i].$1),
                                  style: TextStyle(
                                    color: active
                                        ? AppColors.bombRed
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_isCustom) ...[
                          const SizedBox(height: 16),
                          _RangeRow(
                            label: widget.l10n.min,
                            value: _customMin,
                            min: 1,
                            max: _customMax - 1,
                            onChanged: (v) => setState(() => _customMin = v),
                          ),
                          const SizedBox(height: 8),
                          _RangeRow(
                            label: widget.l10n.max,
                            value: _customMax,
                            min: _customMin + 1,
                            max: 9999,
                            onChanged: (v) => setState(() => _customMax = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    title: widget.l10n.t('numberBombPrepPenaltyTitle'),
                    subtitle: widget.l10n.t('numberBombPrepPenaltyHint'),
                    child: PenaltyPresetCard(
                      preset: widget.penaltyPreset,
                      accentColor: AppColors.bombRed,
                      onChanged: widget.onPenaltyPresetChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: GameUiSpacing.buttonHeight,
            child: ElevatedButton.icon(
              key: const Key('number-bomb-start-button'),
              onPressed: () => widget.onStart(
                min: _effectiveMin,
                max: _effectiveMax,
                playerCount: _playerCount,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bombRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                widget.l10n.startGame,
                style: GameUiText.buttonLabel,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.bombRed.withAlpha(92)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF160B12),
            Color(0xFF0F1320),
            Color(0xFF0A0A12),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.l10n.numberBombSubtitle,
                style: const TextStyle(
                  color: Color(0xFFFF9797),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _buildStatusChip(widget.l10n.playersCount(_playerCount)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.l10n.t('numberBombPrepTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.l10n.t('numberBombPrepHint'),
            style: GameUiText.body.copyWith(
              color: const Color(0xFFD8C1C7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x2EFFFFFF)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bombRed.withAlpha(28),
                  AppColors.bombBlueDark.withAlpha(20),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x10000000),
                          Color(0x00000000),
                          Color(0x12000000),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$_effectiveMin — $_effectiveMax',
                    style: TextStyle(
                      color: Colors.white.withAlpha(235),
                      fontSize: 34,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: 74,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.bombRed.withAlpha(72),
                          AppColors.bombRed.withAlpha(170),
                          AppColors.fingerCyan.withAlpha(110),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: _buildMetricTag(widget.l10n.safeRange),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: _buildMetricTag(widget.l10n.playerLabel(1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.bombRed.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GameUiText.sectionTitle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle, style: GameUiText.body),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bombRed.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.bombRed.withAlpha(70)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFC4C4),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildMetricTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xAA0F0F16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFD7C5D4),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.bombRed.withAlpha(180),
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: AppColors.bombRed,
              overlayColor: AppColors.bombRed.withAlpha(30),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble().clamp(min.toDouble() + 1, 9999),
              divisions: (max - min).clamp(1, 200),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.bombRed, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _PlayingView extends StatelessWidget {
  const _PlayingView({
    required this.state,
    required this.notifier,
    required this.bombPulse,
    required this.l10n,
  });

  final BombState state;
  final NumberBombNotifier notifier;
  final Animation<double> bombPulse;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with back and reset
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => notifier.reset(),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => notifier.reset(),
                child: Text(
                  l10n.reset,
                  style: GameUiText.caption.copyWith(letterSpacing: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.numberBombCurrentPlayer(
            l10n.playerLabel(state.currentPlayerIndex + 1),
          ),
          style: GameUiText.bodyStrong.copyWith(
            color: AppColors.bombRed.withAlpha(220),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${state.minRange}  —  ${state.maxRange}',
              key: ValueKey('${state.minRange}_${state.maxRange}'),
              style: TextStyle(
                color: state.isCritical ? AppColors.bombRed : Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.w200,
                letterSpacing: -1,
                shadows: state.isCritical
                    ? [
                        Shadow(
                          color: AppColors.bombRed.withAlpha(200),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.safeRange,
          style: GameUiText.caption.copyWith(letterSpacing: 1.2),
        ),
        const Spacer(),

        // Bomb icon
        AnimatedBuilder(
          animation: bombPulse,
          builder: (_, __) => Transform.scale(
            scale: bombPulse.value,
            child: Icon(
              Icons.circle,
              size: 80,
              color: AppColors.bombRed
                  .withAlpha((60 + 60 * state.pressureRatio).round()),
              shadows: [
                Shadow(
                  color: AppColors.bombRed
                      .withAlpha((120 * state.pressureRatio).round()),
                  blurRadius: 30,
                ),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Input display
        Container(
          height: 72,
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              state.currentInput.isEmpty
                  ? l10n.inputNumber
                  : state.currentInput,
              key: ValueKey(state.currentInput),
              style: TextStyle(
                color: state.currentInput.isEmpty
                    ? AppColors.textDim
                    : Colors.white,
                fontSize: state.currentInput.isEmpty ? 16 : 48,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
            ),
          ),
        ),

        _BombKeyboard(
          onDigit: notifier.addDigit,
          onBackspace: notifier.backspace,
          onConfirm: notifier.confirmGuess,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _BombKeyboard extends StatelessWidget {
  const _BombKeyboard({
    required this.onDigit,
    required this.onBackspace,
    required this.onConfirm,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onConfirm;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['⌫', '0', '✓'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: _rows.map((row) {
          return Row(
            children: row.map((key) {
              return Expanded(
                child: _KeyButton(
                  label: key,
                  isConfirm: key == '✓',
                  onTap: () {
                    if (key == '⌫') {
                      onBackspace();
                    } else if (key == '✓') {
                      onConfirm();
                    } else {
                      onDigit(key);
                    }
                  },
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.isConfirm = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isConfirm;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _pressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressAnim,
        builder: (_, __) => Container(
          height: 72,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isConfirm
                  ? AppColors.bombRed.withAlpha(150)
                  : Colors.white
                      .withAlpha((30 + 180 * _pressAnim.value).round()),
              width: 1,
            ),
            color: Colors.white.withAlpha(
                (widget.isConfirm ? 50 : 15) + (20 * _pressAnim.value).round()),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isConfirm ? AppColors.bombRed : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplosionOverlay extends StatelessWidget {
  const _ExplosionOverlay({
    required this.state,
    required this.anim,
    required this.blindBoxResult,
    required this.onReset,
    required this.l10n,
  });

  final BombState state;
  final Animation<double> anim;
  final PenaltyBlindBoxResult? blindBoxResult;
  final VoidCallback onReset;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final loserLabel = state.loserPlayerIndex == null
        ? l10n.t('penaltyCurrentPlayerLabel')
        : l10n.playerLabel(state.loserPlayerIndex! + 1);
    final winnerLabels = List.generate(state.playerCount, (index) => index)
        .where((index) => index != state.loserPlayerIndex)
        .map((index) => l10n.playerLabel(index + 1))
        .join(' / ');

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        return Stack(
          children: [
            // White flash at the start
            if (t < 0.15)
              Opacity(
                opacity: (1.0 - t / 0.15).clamp(0.0, 1.0),
                child: Container(color: Colors.white),
              ),

            // Particle explosion
            if (t > 0.1 && t < 0.85)
              CustomPaint(
                painter: _ExplosionPainter(t),
                size: Size.infinite,
              ),

            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.numberBombCurrentPlayer(loserLabel),
                      style: GameUiText.bodyStrong.copyWith(
                        color: AppColors.bombRed.withAlpha(220),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.numberBombLoser(loserLabel),
                      style: GameUiText.bodyStrong,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.numberBombWinners(winnerLabels),
                      style: GameUiText.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GameResultTemplateCard(
                      accentColor: AppColors.bombRed,
                      resultTitle: l10n.t('resultSummary'),
                      resultText: l10n.numberBombTitle,
                      penaltyTitle: l10n.punishment,
                      penaltyText: l10n.t('penaltyBlindBoxTitle'),
                    ),
                    if (blindBoxResult != null) ...[
                      const SizedBox(height: 12),
                      PenaltyBlindBoxOverlay(result: blindBoxResult!),
                    ],
                    const SizedBox(height: 16),
                    GameResultActionBar(
                      accentColor: AppColors.bombRed,
                      primaryLabel: l10n.againRound,
                      onPrimaryTap: onReset,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExplosionPainter extends CustomPainter {
  const _ExplosionPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rng = Random(42);

    for (int i = 0; i < 55; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = rng.nextDouble() * 420 + 80;
      final radius = rng.nextDouble() * 7 + 2;
      final colorT = rng.nextDouble();
      final color = Color.lerp(AppColors.bombRed, Colors.orange, colorT)!;

      final x = center.dx + cos(angle) * speed * t;
      final y = center.dy + sin(angle) * speed * t - 200 * t * t;
      final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        radius * (1 - t * 0.6),
        Paint()..color = color.withAlpha((255 * opacity).round()),
      );
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => old.t != t;
}
