import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/help/game_help_service.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/game_stage_stepper.dart';
import '../../shared/widgets/game_result_template_card.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'models/finger_state.dart';
import 'providers/finger_picker_provider.dart';
import 'painters/finger_ring_painter.dart';
import 'painters/countdown_border_painter.dart';

class FingerPickerScreen extends ConsumerStatefulWidget {
  const FingerPickerScreen({super.key});

  @override
  ConsumerState<FingerPickerScreen> createState() => _FingerPickerScreenState();
}

class _FingerPickerScreenState extends ConsumerState<FingerPickerScreen>
    with TickerProviderStateMixin {
  // 全程呼吸光晕
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // 边框倒计时弧线（countdown 阶段 3s）
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;

  // 圆环旋转（countdown 阶段循环）
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;

  // 锁定脉冲（locked 阶段"开始"按钮缩放）
  late AnimationController _lockCtrl;
  late Animation<double> _lockAnim;

  late Listenable _repaintAnim;
  bool _showHelpButton = false;

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

    // 倒计时阶段 600ms 转一圈
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
      case PickerPhase.locked:
      case PickerPhase.waiting:
        _arcCtrl.reset();
      default:
        _arcCtrl.stop();
    }
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
    });

    final isActive =
        state.phase == PickerPhase.waiting || state.phase == PickerPhase.result;
    final stage = switch (state.phase) {
      PickerPhase.waiting || PickerPhase.locked => GameStage.prepare,
      PickerPhase.countdown || PickerPhase.eliminating => GameStage.playing,
      PickerPhase.result => GameStage.result,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.wheelOrange,
          ),
          // ─── 全屏触控画布 ─────────────────────────────────────────
          Listener(
            onPointerDown: (e) =>
                notifier.addFinger(e.pointer, e.localPosition),
            onPointerMove: (e) =>
                notifier.updateFinger(e.pointer, e.localPosition),
            onPointerUp: (e) => notifier.removeFinger(e.pointer),
            onPointerCancel: (e) => notifier.removeFinger(e.pointer),
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: FingerRingPainter(
                fingers: state.fingers,
                phase: state.phase,
                glowPulse: _glowAnim.value,
                spinAngle: _spinAnim.value,
                elimOrder: state.eliminationOrder,
                elimVisible: state.visibleEliminationCount,
                repaint: _repaintAnim,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // ─── 边框倒计时弧（countdown 阶段）───────────────────────
          if (state.phase == PickerPhase.countdown)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _arcAnim,
                builder: (_, __) => CustomPaint(
                  painter: CountdownBorderPainter(progress: _arcAnim.value),
                  size: MediaQuery.sizeOf(context),
                ),
              ),
            ),

          // ─── 引导文字（无手指时）──────────────────────────────────
          if (state.fingers.isEmpty && state.phase == PickerPhase.waiting)
            IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Icon(
                        Icons.fingerprint,
                        color: AppColors.fingerCyan
                            .withAlpha((55 + 90 * _glowAnim.value).round()),
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Text(
                        l10n.placeFingers,
                        style: TextStyle(
                          color: AppColors.fingerCyan
                              .withAlpha((100 + 80 * _glowAnim.value).round()),
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

          // ─── 只有 1 根手指时的提示 ────────────────────────────────
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

          // ─── 锁定提示文字 ─────────────────────────────────────────
          if (state.phase == PickerPhase.locked)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _glowAnim,
                    builder: (_, __) => Text(
                      l10n.locked,
                      style: TextStyle(
                        color: AppColors.fingerCyan
                            .withAlpha((100 + 80 * _glowAnim.value).round()),
                        fontSize: 15,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ─── 手动"开始"按钮（锁定阶段）────────────────────────────
          // ⚠ 不可加 IgnorePointer，否则按钮无法点击
          // GestureDetector 会拦截 tap，不会穿透到底层 Listener
          if (state.phase == PickerPhase.locked && state.fingers.length >= 2)
            Center(
              child: AnimatedBuilder(
                animation: _lockAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _lockAnim.value, child: child),
                child: GestureDetector(
                  onTap: notifier.startManually,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 44, vertical: 16),
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

          // ─── 倒计时大数字（countdown 阶段）───────────────────────
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

          // ─── 消除阶段进度文字 ─────────────────────────────────────
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
                                  state.eliminationOrder.length)
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

          // ─── 结果覆盖层（胜者标注卡片）────────────────────────────
          if (state.phase == PickerPhase.result)
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: _ResultOverlayContent(state: state, l10n: l10n),
              ),
            ),

          // ─── 结果：再来一次 ───────────────────────────────────────
          if (state.phase == PickerPhase.result)
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GameResultActionBar(
                  accentColor: AppColors.fingerCyan,
                  primaryLabel: l10n.again,
                  onPrimaryTap: notifier.reset,
                ),
              ),
            ),

          // ─── 顶部工具栏（SafeArea）────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 返回按钮（仅在可安全返回的阶段显示）
                      if (isActive)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(Icons.arrow_back_ios,
                                color: AppColors.textDim, size: 20),
                          ),
                        ),
                      const Spacer(),
                      // 选中人数配置
                      if (isActive)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _showWinnersDialog,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people_outline,
                                    color: AppColors.textDim, size: 18),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.selectWinnersCount(state.maxWinners),
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_showHelpButton)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GameHelpButton(
                            onTap: _showGameHelp,
                            iconColor: AppColors.textSecondary,
                            borderColor: AppColors.textDim,
                          ),
                        ),
                    ],
                  ),
                  Center(
                    child: GameStageStepper(
                      stage: stage,
                      accentColor: AppColors.fingerCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── 左边缘划回（仅等待/结果阶段）───────────────────────
          if (isActive)
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
        ],
      ),
    );
  }

  // ──────────────────── 弹窗 ─────────────────────────────────────

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.escapeHint,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
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
              style: const TextStyle(
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.overflowHint,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
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
              style: const TextStyle(
                color: AppColors.fingerCyan,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWinnersDialog() {
    final l10n = AppLocalizations.of(context);
    final current = ref.read(fingerPickerProvider).maxWinners;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF080F1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.fingerCyan.withAlpha(80)),
          ),
          title: Text(
            l10n.selectWinners,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final n = i + 1;
              final selected = current == n;
              return GestureDetector(
                onTap: () {
                  ref.read(fingerPickerProvider.notifier).setMaxWinners(n);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected ? AppColors.fingerCyan : AppColors.textDim,
                      width: selected ? 2 : 1,
                    ),
                    color: selected
                        ? AppColors.fingerCyan.withAlpha(30)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      '$n',
                      style: TextStyle(
                        color: selected
                            ? AppColors.fingerCyan
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── 胜利者结果覆盖层 ────────────────────────────────────────────

class _ResultOverlayContent extends StatelessWidget {
  const _ResultOverlayContent({required this.state, required this.l10n});

  final FingerPickerState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final winners = state.winners;
    if (winners.isEmpty) return const SizedBox.shrink();

    final accentColor = winners.first.neonColor;
    final resultText =
        winners.length == 1 ? l10n.victor : l10n.victorsCount(winners.length);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 48),
          child: GameResultTemplateCard(
            accentColor: accentColor,
            resultTitle: l10n.t('resultSummary'),
            resultText: resultText,
            penaltyTitle: l10n.punishment,
            penaltyText: l10n.t('penaltyGuideParty'),
          ),
        ),
      ),
    );
  }
}
