import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/services/penalty_service.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_top_bar.dart';
import '../../shared/widgets/penalty_blind_box_overlay.dart';
import '../../shared/widgets/penalty_preset_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'models/finger_state.dart';
import 'painters/countdown_border_painter.dart';
import 'painters/finger_ring_painter.dart';
import 'providers/finger_picker_provider.dart';

class FingerPickerScreen extends ConsumerStatefulWidget {
  const FingerPickerScreen({super.key});

  @override
  ConsumerState<FingerPickerScreen> createState() => _FingerPickerScreenState();
}

class _FingerPickerScreenState extends ConsumerState<FingerPickerScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;
  late AnimationController _lockCtrl;
  late Animation<double> _lockAnim;
  late Listenable _repaintAnim;

  bool _showHelpButton = false;
  final Random _penaltyRandom = Random();
  PenaltyPreset _penaltyPreset = PenaltyPreset.defaults;
  PenaltyBlindBoxResult? _blindBoxResult;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _arcAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_arcCtrl);

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    _spinAnim = Tween<double>(begin: 0.0, end: 2 * pi).animate(_spinCtrl);

    _lockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _lockAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _lockCtrl, curve: Curves.easeInOut),
    );

    _repaintAnim = Listenable.merge([_glowAnim, _spinAnim]);
    _initGameHelp();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _arcCtrl.dispose();
    _spinCtrl.dispose();
    _lockCtrl.dispose();
    super.dispose();
  }

  void _handlePhaseChange(PickerPhase phase) {
    switch (phase) {
      case PickerPhase.countdown:
        _arcCtrl
          ..reset()
          ..forward();
      case PickerPhase.setup:
      case PickerPhase.waiting:
      case PickerPhase.locked:
      case PickerPhase.eliminating:
      case PickerPhase.result:
        _arcCtrl
          ..stop()
          ..reset();
    }
  }

  bool _isPlayPhase(PickerPhase phase) {
    return phase == PickerPhase.waiting ||
        phase == PickerPhase.locked ||
        phase == PickerPhase.countdown ||
        phase == PickerPhase.eliminating;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(fingerPickerProvider);
    final notifier = ref.read(fingerPickerProvider.notifier);

    ref.listen(fingerPickerProvider, (prev, next) {
      if (prev?.phase != next.phase) {
        _handlePhaseChange(next.phase);
      }
      if (next.showEscapeAlert && !(prev?.showEscapeAlert ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEscapeDialog();
        });
      }
      if (next.showOverflowAlert && !(prev?.showOverflowAlert ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOverflowDialog();
        });
      }
      if (next.phase == PickerPhase.result &&
          prev?.phase != PickerPhase.result) {
        final losers = _loserColorLabels(next, l10n);
        _blindBoxResult = PenaltyService.resolveBlindBox(
          l10n: l10n,
          random: _penaltyRandom,
          preset: _penaltyPreset,
          losers: losers.isEmpty
              ? <String>[l10n.t('penaltyCurrentPlayerLabel')]
              : losers,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.wheelOrange,
          ),
          if (state.phase == PickerPhase.setup)
            SafeArea(
              child: _FingerPickerPrepView(
                l10n: l10n,
                maxWinners: state.maxWinners,
                penaltyPreset: _penaltyPreset,
                onBack: () => context.pop(),
                onWinnerChanged: notifier.setMaxWinners,
                onPenaltyPresetChanged: (preset) {
                  setState(() => _penaltyPreset = preset);
                },
                onStart: _startGame,
              ),
            ),
          if (_isPlayPhase(state.phase))
            _FingerPickerPlayLayer(
              state: state,
              l10n: l10n,
              notifier: notifier,
              glowAnim: _glowAnim,
              spinAnim: _spinAnim,
              lockAnim: _lockAnim,
              arcAnim: _arcAnim,
              repaintAnim: _repaintAnim,
              onBack: () => context.pop(),
            ),
          if (state.phase == PickerPhase.result)
            SafeArea(
              child: _FingerPickerResultView(
                state: state,
                l10n: l10n,
                blindBoxResult: _blindBoxResult,
                onBack: () => context.pop(),
                onPlayAgain: _playAgain,
                colorLabelBuilder: (color) => _colorLabel(l10n, color),
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
          if (state.phase != PickerPhase.setup)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 200) {
                    context.pop();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  List<String> _loserColorLabels(
      FingerPickerState state, AppLocalizations l10n) {
    return state.fingers.values
        .where((finger) => !finger.isWinner)
        .map((finger) => _colorLabel(l10n, finger.neonColor))
        .toList(growable: false);
  }

  String _colorLabel(AppLocalizations l10n, Color color) {
    final index = AppColors.fingerNeons.indexWhere(
      (item) => item.toARGB32() == color.toARGB32(),
    );
    return switch (index) {
      0 => l10n.t('fingerColorCyan'),
      1 => l10n.t('fingerColorMagenta'),
      2 => l10n.t('fingerColorLime'),
      3 => l10n.t('fingerColorYellow'),
      4 => l10n.t('fingerColorOrange'),
      5 => l10n.t('fingerColorViolet'),
      6 => l10n.t('fingerColorPink'),
      7 => l10n.t('fingerColorSpringGreen'),
      8 => l10n.t('fingerColorAzure'),
      9 => l10n.t('fingerColorAmber'),
      _ => _colorHex(color),
    };
  }

  String _colorHex(Color color) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }

  void _startGame() {
    setState(() => _blindBoxResult = null);
    ref.read(fingerPickerProvider.notifier).startGame();
  }

  void _playAgain() {
    setState(() => _blindBoxResult = null);
    ref.read(fingerPickerProvider.notifier).reset();
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'finger_picker',
        gameTitle: l10n.fingerPicker,
        helpBody: l10n.t('helpFingerPickerBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.fingerPicker,
      helpBody: l10n.t('helpFingerPickerBody'),
    );
  }

  void _showEscapeDialog() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0808),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.bombRed.withAlpha(100)),
        ),
        title: Text(
          l10n.someoneEscaped,
          style: GameUiText.sectionTitle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.escapeHint,
          style: GameUiText.body,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(fingerPickerProvider.notifier).dismissEscapeAlert();
            },
            child: Text(
              l10n.okRetry,
              style: GameUiText.bodyStrong.copyWith(
                color: AppColors.fingerCyan,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverflowDialog() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF080F1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.fingerCyan.withAlpha(100)),
        ),
        title: Text(
          l10n.overflowTitle,
          style: GameUiText.sectionTitle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.overflowHint,
          style: GameUiText.body,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(fingerPickerProvider.notifier).dismissOverflowAlert();
            },
            child: Text(
              l10n.ok,
              style: GameUiText.bodyStrong.copyWith(
                color: AppColors.fingerCyan,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FingerPickerPrepView extends StatelessWidget {
  const _FingerPickerPrepView({
    required this.l10n,
    required this.maxWinners,
    required this.penaltyPreset,
    required this.onBack,
    required this.onWinnerChanged,
    required this.onPenaltyPresetChanged,
    required this.onStart,
  });

  final AppLocalizations l10n;
  final int maxWinners;
  final PenaltyPreset penaltyPreset;
  final VoidCallback onBack;
  final ValueChanged<int> onWinnerChanged;
  final ValueChanged<PenaltyPreset> onPenaltyPresetChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GameUiSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          GameTopBar(
            title: l10n.fingerPicker,
            onBack: onBack,
            accentColor: AppColors.fingerCyan,
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
                    title: l10n.t('fingerPrepWinnersTitle'),
                    subtitle: l10n.t('fingerPrepWinnersHint'),
                    trailing:
                        _buildStatusChip(l10n.selectWinnersCount(maxWinners)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            key: const Key('finger-picker-winner-slider'),
                            value: maxWinners.toDouble(),
                            min: 1,
                            max: kMaxFingerPlayers.toDouble(),
                            divisions: kMaxFingerPlayers - 1,
                            activeColor: AppColors.fingerCyan,
                            onChanged: (value) =>
                                onWinnerChanged(value.round()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(kMaxFingerPlayers, (index) {
                            final count = index + 1;
                            final active = count == maxWinners;
                            return GestureDetector(
                              onTap: () => onWinnerChanged(count),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.fingerCyan
                                        : AppColors.textDim,
                                    width: active ? 1.5 : 1,
                                  ),
                                  color: active
                                      ? AppColors.fingerCyan.withAlpha(24)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    color: active
                                        ? AppColors.fingerCyan
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  PenaltyPresetCard(
                    preset: penaltyPreset,
                    accentColor: AppColors.fingerCyan,
                    onChanged: onPenaltyPresetChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: GameUiSpacing.buttonHeight,
            child: ElevatedButton.icon(
              key: const Key('finger-picker-start-button'),
              onPressed: onStart,
              style: GameUiSurface.primaryButton(AppColors.fingerCyan),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                l10n.startGame,
                style: GameUiText.buttonLabel.copyWith(
                  color: GameUiSurface.foregroundOn(AppColors.fingerCyan),
                ),
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
      decoration: GameUiSurface.heroPanel(
        accentColor: AppColors.fingerCyan,
        secondaryColor: GameUiSurface.shiftHue(AppColors.fingerCyan, by: 58),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.fingerPickerSub,
                style: const TextStyle(
                  color: Color(0xFF8BE8FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              _buildStatusChip(l10n.selectWinnersCount(maxWinners)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.t('fingerPrepTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('fingerPrepHint'),
            style: GameUiText.body.copyWith(
              color: const Color(0xFFC6D6E4),
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
      decoration: GameUiSurface.panel(accentColor: AppColors.fingerCyan),
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
        color: AppColors.fingerCyan.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.fingerCyan.withAlpha(70)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFA8F8FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _FingerPickerPlayLayer extends StatelessWidget {
  const _FingerPickerPlayLayer({
    required this.state,
    required this.l10n,
    required this.notifier,
    required this.glowAnim,
    required this.spinAnim,
    required this.lockAnim,
    required this.arcAnim,
    required this.repaintAnim,
    required this.onBack,
  });

  final FingerPickerState state;
  final AppLocalizations l10n;
  final FingerPickerNotifier notifier;
  final Animation<double> glowAnim;
  final Animation<double> spinAnim;
  final Animation<double> lockAnim;
  final Animation<double> arcAnim;
  final Listenable repaintAnim;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          onPointerDown: (e) => notifier.addFinger(e.pointer, e.localPosition),
          onPointerMove: (e) =>
              notifier.updateFinger(e.pointer, e.localPosition),
          onPointerUp: (e) => notifier.removeFinger(e.pointer),
          onPointerCancel: (e) => notifier.removeFinger(e.pointer),
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: FingerRingPainter(
              fingers: state.fingers,
              phase: state.phase,
              glowPulse: glowAnim.value,
              spinAngle: spinAnim.value,
              elimOrder: state.eliminationOrder,
              elimVisible: state.visibleEliminationCount,
              repaint: repaintAnim,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (state.phase == PickerPhase.countdown)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: arcAnim,
              builder: (_, __) => CustomPaint(
                painter: CountdownBorderPainter(progress: arcAnim.value),
                size: MediaQuery.sizeOf(context),
              ),
            ),
          ),
        if (state.fingers.isEmpty && state.phase == PickerPhase.waiting)
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: glowAnim,
                    builder: (_, __) => Icon(
                      Icons.fingerprint,
                      color: AppColors.fingerCyan.withAlpha(
                        (55 + 90 * glowAnim.value).round(),
                      ),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: glowAnim,
                    builder: (_, __) => Text(
                      l10n.placeFingers,
                      style: TextStyle(
                        color: AppColors.fingerCyan.withAlpha(
                          (100 + 80 * glowAnim.value).round(),
                        ),
                        fontSize: 22,
                        letterSpacing: 5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.placeFingersEn,
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (state.fingers.length == 1 && state.phase == PickerPhase.waiting)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  l10n.waitingMore,
                  style: TextStyle(
                    color: AppColors.fingerCyan.withAlpha(100),
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        if (state.phase == PickerPhase.locked)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: glowAnim,
                  builder: (_, __) => Text(
                    l10n.locked,
                    style: TextStyle(
                      color: AppColors.fingerCyan.withAlpha(
                        (100 + 80 * glowAnim.value).round(),
                      ),
                      fontSize: 15,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (state.phase == PickerPhase.locked && state.fingers.length >= 2)
          Center(
            child: AnimatedBuilder(
              animation: lockAnim,
              builder: (_, child) =>
                  Transform.scale(scale: lockAnim.value, child: child),
              child: GestureDetector(
                onTap: notifier.startManually,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: AppColors.fingerCyan.withAlpha(160),
                      width: 1.5,
                    ),
                    color: AppColors.fingerCyan.withAlpha(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fingerCyan.withAlpha(50),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.start,
                    style: const TextStyle(
                      color: AppColors.fingerCyan,
                      letterSpacing: 10,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (state.phase == PickerPhase.countdown)
          IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(state.countdownValue),
                tween: Tween(begin: 1.7, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, scale, __) => Transform.scale(
                  scale: scale,
                  child: Text(
                    '${state.countdownValue}',
                    style: TextStyle(
                      color: AppColors.fingerCyan,
                      fontSize: 140,
                      fontWeight: FontWeight.w100,
                      letterSpacing: -4,
                      shadows: [
                        Shadow(
                          color: AppColors.fingerCyan.withAlpha(210),
                          blurRadius: 60,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (state.phase == PickerPhase.eliminating)
          Positioned(
            bottom: 72,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    key: ValueKey(state.visibleEliminationCount),
                    state.visibleEliminationCount == 0
                        ? l10n.fateSpinning
                        : state.visibleEliminationCount <
                                state.eliminationOrder.length
                            ? l10n.eliminatedCount(
                                state.visibleEliminationCount,
                                state.eliminationOrder.length,
                              )
                            : l10n.reveal,
                    style: TextStyle(
                      color: AppColors.bombRed.withAlpha(200),
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.fingerCyan.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: AppColors.fingerCyan.withAlpha(70)),
                    ),
                    child: Text(
                      l10n.selectWinnersCount(state.maxWinners),
                      style: GameUiText.caption.copyWith(
                        color: AppColors.fingerCyan,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FingerPickerResultView extends StatelessWidget {
  const _FingerPickerResultView({
    required this.state,
    required this.l10n,
    required this.blindBoxResult,
    required this.onBack,
    required this.onPlayAgain,
    required this.colorLabelBuilder,
  });

  final FingerPickerState state;
  final AppLocalizations l10n;
  final PenaltyBlindBoxResult? blindBoxResult;
  final VoidCallback onBack;
  final VoidCallback onPlayAgain;
  final String Function(Color color) colorLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final winners = state.winners;
    final accentColor =
        winners.isEmpty ? AppColors.fingerCyan : winners.first.neonColor;
    final resultText = _buildResultText(winners, accentColor);

    return Padding(
      padding: GameUiSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          GameTopBar(
            title: l10n.fingerPicker,
            onBack: onBack,
            accentColor: accentColor,
          ),
          const SizedBox(height: GameUiSpacing.blockGap),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: GameUiSurface.panel(accentColor: accentColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('fingerResultTitle'),
                          style: GameUiText.sectionTitle,
                        ),
                        const SizedBox(height: 8),
                        resultText,
                      ],
                    ),
                  ),
                  if (blindBoxResult != null) ...[
                    const SizedBox(height: 12),
                    PenaltyBlindBoxOverlay(result: blindBoxResult!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GameResultActionBar(
            accentColor: accentColor,
            primaryLabel: l10n.again,
            onPrimaryTap: onPlayAgain,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResultText(List<FingerData> winners, Color accentColor) {
    final baseStyle = GameUiText.bodyStrong.copyWith(color: Colors.white);
    if (winners.isEmpty) {
      return Text(l10n.t('fingerResultNoColor'), style: baseStyle);
    }

    if (winners.length == 1) {
      final colorLabel = colorLabelBuilder(winners.first.neonColor);
      final prefix = l10n.t('fingerResultSingleColor', {'color': ''});
      return RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: prefix),
            TextSpan(
              text: colorLabel,
              style: baseStyle.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final prefix = l10n.t('fingerResultMultiColors', {'colors': ''});
    final spans = <InlineSpan>[TextSpan(text: prefix)];
    for (var i = 0; i < winners.length; i++) {
      final finger = winners[i];
      spans.add(
        TextSpan(
          text: colorLabelBuilder(finger.neonColor),
          style: baseStyle.copyWith(
            color: finger.neonColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      if (i != winners.length - 1) {
        spans.add(const TextSpan(text: ' / '));
      }
    }
    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}
