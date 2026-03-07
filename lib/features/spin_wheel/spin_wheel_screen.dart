import 'dart:ui';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/help/game_help_service.dart';
import '../../core/haptics/haptic_service.dart';
import '../../core/audio/audio_service.dart';
import '../../core/constants/app_sounds.dart';
import '../../shared/styles/game_ui_style.dart';
import '../../shared/widgets/game_result_action_bar.dart';
import '../../shared/widgets/web3_game_background.dart';
import 'models/wheel_segment.dart';
import 'providers/spin_wheel_provider.dart';
import 'painters/wheel_painter.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

String _localizedWheelName(AppLocalizations l10n, WheelConfig config) {
  final key = config.nameLocalizationKey;
  if (key != null && key.isNotEmpty) {
    return l10n.t(key);
  }
  return l10n.presetDisplayName(config.name);
}

String _localizedWheelSegmentLabel(
    AppLocalizations l10n, WheelSegment segment) {
  final key = segment.labelLocalizationKey;
  if (key != null && key.isNotEmpty) {
    return l10n.t(key);
  }
  return segment.label;
}

WheelConfig _editableWheelConfig(AppLocalizations l10n, WheelConfig config) {
  if (!config.isBuiltIn) {
    return config;
  }
  return WheelConfig(
    id: config.id,
    name: _localizedWheelName(l10n, config),
    isPrankMode: config.isPrankMode,
    segments: config.segments
        .map(
          (segment) => WheelSegment(
            label: _localizedWheelSegmentLabel(l10n, segment),
            color: segment.color,
            weight: segment.weight,
          ),
        )
        .toList(growable: false),
  );
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _resultController;
  late Animation<double> _resultAnim;

  double _lastDragAngle = 0;
  double _dragVelocity = 0;
  bool _showHelpButton = false;
  bool _inSetup = true;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultAnim = _buildSpringAnim();

    final notifier = ref.read(spinWheelProvider.notifier);
    notifier.initTicker(this);
    notifier.onSegmentCross = (speed) {
      if (speed > 10) {
        HapticService.selectionClick();
      } else if (speed > 4) {
        HapticService.lightImpact();
      } else {
        HapticService.mediumImpact();
      }
      AudioService.play(AppSounds.wheelTick, volume: 0.6);
    };
    _initGameHelp();
  }

  Animation<double> _buildSpringAnim() {
    return TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.2)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.2, end: 0.95)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20),
    ]).animate(_resultController);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Offset _centerOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final size = box.size;
    return Offset(size.width / 2, size.height * 0.42);
  }

  double _angleFrom(BuildContext ctx, Offset globalPos) {
    final center = _centerOf(ctx);
    final box = ctx.findRenderObject() as RenderBox?;
    final local = box?.globalToLocal(globalPos) ?? globalPos;
    return atan2(local.dy - center.dy, local.dx - center.dx);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(spinWheelProvider);
    final notifier = ref.read(spinWheelProvider.notifier);
    final screenH = MediaQuery.sizeOf(context).height;
    final wheelSize = MediaQuery.sizeOf(context).width * 0.88;

    ref.listen(spinWheelProvider, (prev, next) {
      if (prev?.phase != SpinPhase.result &&
          next.phase == SpinPhase.result &&
          next.resultSegment != null) {
        _resultController.reset();
        _resultController.forward();
        HapticService.notificationSuccess();
        AudioService.play(AppSounds.wheelResult);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Web3GameBackground(
            accentColor: AppColors.wheelOrange,
            secondaryColor: AppColors.fingerCyan,
          ),
          SafeArea(
            child: Padding(
              padding: GameUiSpacing.screenPadding,
              child: Column(
                children: [
                  _TopBar(
                    title: l10n.spinWheel,
                    showHelpButton: _showHelpButton,
                    onBack: () => context.pop(),
                    onHelp: _showGameHelp,
                  ),
                  const SizedBox(height: GameUiSpacing.sectionGap),
                  if (_inSetup) ...[
                    Expanded(
                      child: _SpinWheelPrepView(
                        l10n: l10n,
                        state: state,
                        notifier: notifier,
                        onAddWheel: () =>
                            _showCreateSheet(context, state, notifier),
                        onEditWheel: () =>
                            _showEditorSheet(context, state, notifier),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: GameUiSpacing.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () => _startGame(notifier),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.wheelOrange,
                          foregroundColor: Colors.white,
                          textStyle: GameUiText.buttonLabel,
                        ),
                        child: Text(l10n.start),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: _SpinWheelPlayView(
                        l10n: l10n,
                        state: state,
                        notifier: notifier,
                        glowAnimation: _glowAnim,
                        screenHeight: screenH,
                        wheelSize: wheelSize,
                        onPanStart: (d) {
                          _lastDragAngle =
                              _angleFrom(context, d.globalPosition);
                          _dragVelocity = 0;
                        },
                        onPanUpdate: (d) {
                          final current = _angleFrom(context, d.globalPosition);
                          final delta = current - _lastDragAngle;
                          _dragVelocity = delta * 60;
                          _lastDragAngle = current;
                          _dismissResult(notifier);
                        },
                        onPanEnd: (d) {
                          final vel = d.velocity.pixelsPerSecond.distance;
                          final sign = _dragVelocity.sign;
                          final radius = wheelSize / 2;
                          notifier.startSpin(vel * sign, radius);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Result overlay
          if (state.phase == SpinPhase.result && state.resultSegment != null)
            _ResultOverlay(
              l10n: l10n,
              wheelTitle: _localizedWheelName(l10n, state.config),
              segment: state.resultSegment!,
              naturalOptionLabel: state.naturalResultIndex == null
                  ? null
                  : _localizedWheelSegmentLabel(
                      l10n,
                      state.config.segments[state.naturalResultIndex!],
                    ),
              isPrankMode: state.config.isPrankMode,
              animation: _resultAnim,
              onDismiss: () => _dismissResult(notifier),
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
        ],
      ),
    );
  }

  void _initGameHelp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await GameHelpService.ensureFirstTimeShown(
        context: context,
        gameId: 'spin_wheel',
        gameTitle: l10n.spinWheel,
        helpBody: l10n.t('helpSpinWheelBody'),
      );
      if (mounted) setState(() => _showHelpButton = true);
    });
  }

  void _showGameHelp() {
    final l10n = AppLocalizations.of(context);
    GameHelpService.showGameHelpDialog(
      context,
      gameTitle: l10n.spinWheel,
      helpBody: l10n.t('helpSpinWheelBody'),
    );
  }

  void _startGame(SpinWheelNotifier notifier) {
    HapticService.mediumImpact();
    notifier.dismissResult();
    setState(() {
      _inSetup = false;
    });
  }

  void _dismissResult(SpinWheelNotifier notifier) {
    notifier.dismissResult();
  }

  void _showEditorSheet(
      BuildContext ctx, SpinWheelState state, SpinWheelNotifier notifier) {
    final l10n = AppLocalizations.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WheelEditorSheet(
        l10n: l10n,
        initialConfig: _editableWheelConfig(l10n, state.config),
        mode: _WheelEditorMode.edit,
        onSave: (template) => notifier.saveTemplate(
          template,
          originalTemplateId: state.config.id,
        ),
      ),
    );
  }

  void _showCreateSheet(
      BuildContext ctx, SpinWheelState state, SpinWheelNotifier notifier) {
    final l10n = AppLocalizations.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WheelEditorSheet(
        l10n: l10n,
        initialConfig: _buildDraftWheelConfig(l10n, state.config.isPrankMode),
        mode: _WheelEditorMode.create,
        onSave: (template) => notifier.saveTemplate(template),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.showHelpButton,
    required this.onBack,
    required this.onHelp,
  });

  final String title;
  final bool showHelpButton;
  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child:
              const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GameUiText.navTitle,
          ),
        ),
        const SizedBox(width: 12),
        showHelpButton
            ? GameHelpButton(
                onTap: onHelp,
                iconColor: AppColors.textSecondary,
                borderColor: AppColors.textDim,
              )
            : const SizedBox(width: 32, height: 32),
      ],
    );
  }
}

class _SpinWheelPrepView extends StatelessWidget {
  const _SpinWheelPrepView({
    required this.l10n,
    required this.state,
    required this.notifier,
    required this.onAddWheel,
    required this.onEditWheel,
  });

  final AppLocalizations l10n;
  final SpinWheelState state;
  final SpinWheelNotifier notifier;
  final VoidCallback onAddWheel;
  final VoidCallback onEditWheel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: l10n.t('spinWheelTemplateTitle'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PresetSelectorBar(
                  l10n: l10n,
                  state: state,
                  notifier: notifier,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddWheel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.wheelOrange.withAlpha(120),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppColors.wheelOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(l10n.addWheel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditWheel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textDim),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.editWheel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.t('spinWheelModeTitle'),
            trailing: GameHelpButton(
              key: const Key('spinWheelModeHelpButton'),
              onTap: () => _showSpinWheelModeHelpDialog(context, l10n),
              iconColor: AppColors.textSecondary,
              borderColor: AppColors.textDim,
            ),
            child: _ModeSelector(
              l10n: l10n,
              isPrank: state.config.isPrankMode,
              onSelected: notifier.setPrankMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinWheelPlayView extends StatelessWidget {
  const _SpinWheelPlayView({
    required this.l10n,
    required this.state,
    required this.notifier,
    required this.glowAnimation,
    required this.screenHeight,
    required this.wheelSize,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final AppLocalizations l10n;
  final SpinWheelState state;
  final SpinWheelNotifier notifier;
  final Animation<double> glowAnimation;
  final double screenHeight;
  final double wheelSize;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    final localizedSegments = state.config.segments
        .map(
          (segment) => segment.copyWith(
            label: _localizedWheelSegmentLabel(l10n, segment),
          ),
        )
        .toList(growable: false);
    final wheelName = _localizedWheelName(l10n, state.config);
    final liveSegment = state.liveSegmentIndex == null
        ? null
        : localizedSegments[state.liveSegmentIndex!];
    final prankTargetSegment = !state.config.isPrankMode
        ? null
        : (state.prankTargetIndex == null
            ? liveSegment
            : localizedSegments[state.prankTargetIndex!]);
    final targetLockProgress = state.config.isPrankMode &&
            prankTargetSegment != null &&
            state.phase != SpinPhase.idle
        ? 0.18 + state.prankBiasProgress * 0.82
        : 0.0;
    final pointerColor = state.config.isPrankMode && prankTargetSegment != null
        ? Color.lerp(
            AppColors.wheelOrange,
            prankTargetSegment.color,
            0.2 + state.prankBiasProgress * 0.8,
          )
        : AppColors.wheelOrange;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.56,
          child: GestureDetector(
            onPanStart: onPanStart,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanEnd,
            child: AnimatedBuilder(
              animation: glowAnimation,
              builder: (_, __) => Center(
                child: CustomPaint(
                  painter: WheelPainter(
                    segments: localizedSegments,
                    totalWeight: state.config.totalWeight,
                    angle: state.angle,
                    accentColor: AppColors.wheelOrange,
                    glowIntensity: glowAnimation.value,
                    speed: state.angularVelocity.abs(),
                    activeIndex: state.liveSegmentIndex,
                    targetIndex: state.config.isPrankMode
                        ? state.prankTargetIndex
                        : null,
                    targetLockProgress: targetLockProgress,
                    pointerColor: pointerColor,
                  ),
                  size: Size(wheelSize, wheelSize),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          state.config.isPrankMode
              ? '${l10n.slideToSpin}  •  $wheelName  •  ${l10n.prankActive}'
              : '${l10n.slideToSpin}  •  $wheelName',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: state.config.isPrankMode
                ? AppColors.bombRed.withAlpha(180)
                : AppColors.textDim,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _SpinModeTelemetryCard(
          l10n: l10n,
          phase: state.phase,
          isPrankMode: state.config.isPrankMode,
          liveSegment: liveSegment,
          prankTargetSegment: prankTargetSegment,
          biasProgress: state.prankBiasProgress,
        ),
      ],
    );
  }
}

class _SpinModeTelemetryCard extends StatelessWidget {
  const _SpinModeTelemetryCard({
    required this.l10n,
    required this.phase,
    required this.isPrankMode,
    required this.liveSegment,
    required this.prankTargetSegment,
    required this.biasProgress,
  });

  final AppLocalizations l10n;
  final SpinPhase phase;
  final bool isPrankMode;
  final WheelSegment? liveSegment;
  final WheelSegment? prankTargetSegment;
  final double biasProgress;

  @override
  Widget build(BuildContext context) {
    final isPulling = phase == SpinPhase.spinning && biasProgress > 0.18;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isPrankMode ? AppColors.bombRed.withAlpha(120) : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeSignalRow(
            title: l10n.t('spinWheelLiveLanding'),
            segment: liveSegment,
            accentColor: Colors.white,
            emphasized: !isPrankMode,
          ),
          if (isPrankMode) ...[
            const SizedBox(height: 10),
            _ModeSignalRow(
              title: l10n.t('spinWheelCheatLock'),
              segment: prankTargetSegment,
              accentColor: AppColors.bombRed,
              emphasized: isPulling,
            ),
          ],
          const SizedBox(height: 10),
          Text(
            isPrankMode
                ? (isPulling
                    ? l10n.t('spinWheelPrankPullHint')
                    : l10n.t('spinWheelPrankWaitHint'))
                : l10n.t('spinWheelFairHint'),
            style: TextStyle(
              color: isPrankMode
                  ? AppColors.bombRed.withAlpha(isPulling ? 220 : 170)
                  : AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSignalRow extends StatelessWidget {
  const _ModeSignalRow({
    required this.title,
    required this.segment,
    required this.accentColor,
    required this.emphasized,
  });

  final String title;
  final WheelSegment? segment;
  final Color accentColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            title,
            style: TextStyle(
              color: accentColor.withAlpha(emphasized ? 220 : 170),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: (segment?.color ?? Colors.white).withAlpha(24),
              border: Border.all(
                color: (segment?.color ?? Colors.white).withAlpha(
                  emphasized ? 180 : 120,
                ),
              ),
              boxShadow: [
                if (emphasized && segment != null)
                  BoxShadow(
                    color: segment!.color.withAlpha(70),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Text(
              segment?.label ?? '--',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameUiText.bodyStrong.copyWith(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GameUiText.bodyStrong,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Future<void> _showSpinWheelModeHelpDialog(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF101010),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      title: Text(
        l10n.t('spinWheelModeHelpTitle'),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Text(
        l10n.t('spinWheelModeHelpBody'),
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 14,
          height: 1.55,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.ok,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _PresetSelectorBar extends StatelessWidget {
  const _PresetSelectorBar({
    required this.l10n,
    required this.state,
    required this.notifier,
  });

  final AppLocalizations l10n;
  final SpinWheelState state;
  final SpinWheelNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.templates.length,
        itemBuilder: (_, i) {
          final preset = state.templates[i];
          final active = state.selectedTemplateId == preset.id;
          return _TemplateChip(
            key: ValueKey('template-chip-${preset.id}'),
            label: _localizedWheelName(l10n, preset),
            active: active,
            canDelete: !preset.isBuiltIn,
            onTap: () {
              notifier.loadConfig(preset);
              HapticService.lightImpact();
            },
            onDelete: () async {
              await notifier.deleteTemplate(preset.id);
              HapticService.mediumImpact();
            },
          );
        },
      ),
    );
  }
}

class _TemplateChip extends StatefulWidget {
  const _TemplateChip({
    super.key,
    required this.label,
    required this.active,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final bool active;
  final bool canDelete;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  State<_TemplateChip> createState() => _TemplateChipState();
}

class _TemplateChipState extends State<_TemplateChip> {
  bool _showDeleteButton = false;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        if (widget.canDelete)
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(
              duration: const Duration(seconds: 2),
            ),
            (instance) {
              instance.onLongPress = () {
                if (!mounted) return;
                setState(() => _showDeleteButton = true);
                HapticService.mediumImpact();
              };
            },
          ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showDeleteButton) {
            setState(() => _showDeleteButton = false);
            return;
          }
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 6),
                child: Container(
                  key: Key('template-chip-surface-${widget.label}'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.active
                          ? AppColors.wheelOrange
                          : AppColors.textDim,
                      width: widget.active ? 1.5 : 1,
                    ),
                    color: widget.active
                        ? AppColors.wheelOrange.withAlpha(20)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.active
                            ? AppColors.wheelOrange
                            : AppColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              if (_showDeleteButton && widget.canDelete)
                Positioned(
                  key: Key('delete-template-${widget.label}'),
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      await widget.onDelete();
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5484D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Editor bottom sheet ───────────────────────────

enum _WheelEditorMode { create, edit }

WheelConfig _buildDraftWheelConfig(
  AppLocalizations l10n,
  bool isPrankMode,
) {
  return WheelConfig(
    id: 'draft_wheel',
    name: '',
    isPrankMode: isPrankMode,
    segments: [
      WheelSegment(
          label: l10n.t('wheelDefaultOption1'), color: const Color(0xFFF43F5E)),
      WheelSegment(
          label: l10n.t('wheelDefaultOption2'), color: const Color(0xFF00D4FF)),
      WheelSegment(
          label: l10n.t('wheelDefaultOption3'), color: const Color(0xFFFF8C00)),
      WheelSegment(
          label: l10n.t('wheelDefaultOption4'), color: const Color(0xFF00FF88)),
    ],
  );
}

class _WheelEditorSheet extends StatefulWidget {
  const _WheelEditorSheet({
    required this.l10n,
    required this.initialConfig,
    required this.mode,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final WheelConfig initialConfig;
  final _WheelEditorMode mode;
  final Future<void> Function(WheelConfig template) onSave;

  @override
  State<_WheelEditorSheet> createState() => _WheelEditorSheetState();
}

class _WheelEditorSheetState extends State<_WheelEditorSheet> {
  static const _paletteColors = [
    Color(0xFFF43F5E),
    Color(0xFF7C3AED),
    Color(0xFF00D4FF),
    Color(0xFF00FF88),
    Color(0xFFFFE135),
    Color(0xFFFF8C00),
    Color(0xFFFF6B35),
    Color(0xFF9B00FF),
    Color(0xFFFF44B8),
    Color(0xFF00A8FF),
    Color(0xFFFFFFFF),
  ];

  late final TextEditingController _templateNameController;
  late List<WheelSegment> _segments;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _templateNameController =
        TextEditingController(text: widget.initialConfig.name)
          ..addListener(() => setState(() {}));
    _segments = widget.initialConfig.segments
        .map((segment) => segment.copyWith())
        .toList();
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _templateNameController.text.trim().isNotEmpty &&
        _segments.length >= 2 &&
        _segments.every((segment) => segment.label.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.wheelOrange.withAlpha(60),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    widget.mode == _WheelEditorMode.create
                        ? l10n.addWheel
                        : l10n.editWheel,
                    style: GameUiText.navTitle,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _canSubmit && !_isSaving ? _submit : null,
                    child: Text(
                      widget.mode == _WheelEditorMode.create
                          ? l10n.createWheel
                          : l10n.saveWheel,
                      style: TextStyle(
                        color: _canSubmit
                            ? AppColors.wheelOrange
                            : AppColors.textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollCtrl,
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                header: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.wheelName,
                        style: GameUiText.body.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('wheelTemplateNameField'),
                        controller: _templateNameController,
                        maxLength: 16,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.wheelNameHint,
                          hintStyle: const TextStyle(color: AppColors.textDim),
                          counterStyle:
                              const TextStyle(color: AppColors.textDim),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0x33FFFFFF),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppColors.wheelOrange.withAlpha(160),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.wheelOptionsTitle,
                              style: GameUiText.bodyStrong.copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _addSegmentDialog(context),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: AppColors.wheelOrange,
                            ),
                            label: Text(
                              l10n.addOption,
                              style: const TextStyle(
                                color: AppColors.wheelOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                itemCount: _segments.length,
                onReorder: _reorderSegments,
                itemBuilder: (_, i) {
                  final seg = _segments[i];
                  return _SegmentTile(
                    key: ValueKey('$i-${seg.label}'),
                    segment: seg,
                    index: i,
                    canDelete: _segments.length > 2,
                    onEdit: () => _editSegmentDialog(context, i, seg),
                    onDelete: () => _removeSegment(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSegmentDialog(BuildContext ctx) {
    final l10n = widget.l10n;
    _showSegmentDialog(
      ctx,
      title: l10n.addOption,
      optionNameHint: l10n.optionName,
      colorLabel: l10n.color,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.confirm,
      initialLabel: '',
      initialColor: _paletteColors[0],
      onConfirm: (label, color) {
        if (label.isNotEmpty) {
          setState(() {
            _segments = [
              ..._segments,
              WheelSegment(label: label, color: color),
            ];
          });
          HapticService.lightImpact();
        }
      },
    );
  }

  void _editSegmentDialog(BuildContext ctx, int index, WheelSegment seg) {
    final l10n = widget.l10n;
    _showSegmentDialog(
      ctx,
      title: l10n.editOption,
      optionNameHint: l10n.optionName,
      colorLabel: l10n.color,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.confirm,
      initialLabel: seg.label,
      initialColor: seg.color,
      onConfirm: (label, color) {
        if (label.isNotEmpty) {
          setState(() {
            _segments[index] = WheelSegment(label: label, color: color);
          });
          HapticService.lightImpact();
        }
      },
    );
  }

  void _removeSegment(int index) {
    if (_segments.length <= 2) return;
    setState(() {
      _segments = [..._segments]..removeAt(index);
    });
  }

  void _reorderSegments(int oldIndex, int newIndex) {
    setState(() {
      final updated = [..._segments];
      if (newIndex > oldIndex) newIndex -= 1;
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _segments = updated;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSaving) return;

    setState(() => _isSaving = true);
    final template = widget.initialConfig.copyWith(
      name: _templateNameController.text.trim(),
      segments: List<WheelSegment>.unmodifiable(_segments),
    );
    await widget.onSave(template);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSegmentDialog(
    BuildContext ctx, {
    required String title,
    required String optionNameHint,
    required String colorLabel,
    required String cancelLabel,
    required String confirmLabel,
    required String initialLabel,
    required Color initialColor,
    required void Function(String, Color) onConfirm,
  }) {
    final textCtrl = TextEditingController(text: initialLabel);
    Color picked = initialColor;

    showDialog<void>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.wheelOrange.withAlpha(80),
            ),
          ),
          title: Text(
            title,
            style: GameUiText.bodyStrong.copyWith(
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
                autofocus: true,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: optionNameHint,
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  counterStyle: const TextStyle(color: AppColors.textDim),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.wheelOrange.withAlpha(100),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.wheelOrange),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                colorLabel,
                style: GameUiText.body.copyWith(
                  color: AppColors.textDim,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _paletteColors.map((c) {
                  final selected = picked == c;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setS(() => picked = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          if (selected)
                            BoxShadow(
                              color: c.withAlpha(100),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(
                cancelLabel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                onConfirm(textCtrl.text.trim(), picked);
              },
              child: Text(
                confirmLabel,
                style: const TextStyle(color: AppColors.wheelOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    super.key,
    required this.segment,
    required this.index,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final WheelSegment segment;
  final int index;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: segment.color,
            boxShadow: [
              BoxShadow(
                color: segment.color.withAlpha(100),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        title: Text(
          segment.label,
          style: GameUiText.bodyStrong.copyWith(
            letterSpacing: 0.6,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.textDim, size: 18),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFF884444), size: 18),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            const Icon(Icons.drag_handle, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Mode toggle ───────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.l10n,
    required this.isPrank,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final bool isPrank;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        color: Colors.white.withAlpha(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeOption(
              label: l10n.fair,
              selected: !isPrank,
              activeColor: AppColors.wheelOrange,
              onTap: () => onSelected(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ModeOption(
              label: l10n.prank,
              selected: isPrank,
              activeColor: AppColors.bombRed,
              onTap: () => onSelected(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? activeColor.withAlpha(180) : Colors.white12,
            ),
            color: selected ? activeColor.withAlpha(28) : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GameUiText.bodyStrong.copyWith(
                color: selected ? activeColor : AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Result overlay ───────────────────────────

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.l10n,
    required this.wheelTitle,
    required this.segment,
    required this.isPrankMode,
    required this.animation,
    required this.onDismiss,
    this.naturalOptionLabel,
  });

  final AppLocalizations l10n;
  final String wheelTitle;
  final WheelSegment segment;
  final bool isPrankMode;
  final String? naturalOptionLabel;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.black.withAlpha(100)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: animation,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinWheelResultDetails(
                        wheelTitle: wheelTitle,
                        optionLabel: _localizedWheelSegmentLabel(l10n, segment),
                        accentColor: segment.color,
                        isPrankMode: isPrankMode,
                        naturalOptionLabel: naturalOptionLabel,
                      ),
                      const SizedBox(height: 14),
                      GameResultActionBar(
                        accentColor: segment.color,
                        primaryLabel: l10n.touchToContinue,
                        onPrimaryTap: onDismiss,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpinWheelResultDetails extends StatelessWidget {
  const SpinWheelResultDetails({
    super.key,
    required this.wheelTitle,
    required this.optionLabel,
    required this.accentColor,
    this.isPrankMode = false,
    this.naturalOptionLabel,
  });

  final String wheelTitle;
  final String optionLabel;
  final Color accentColor;
  final bool isPrankMode;
  final String? naturalOptionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.t('spinWheelResultHeadline', {'template': wheelTitle}),
            style: GameUiText.bodyStrong.copyWith(
              color: accentColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.t('spinWheelResultTypeLabel'),
            style: GameUiText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            wheelTitle,
            style: GameUiText.bodyStrong.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.t('spinWheelSelectedOption'),
            style: GameUiText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withAlpha(120)),
            ),
            child: Text(
              optionLabel,
              style: GameUiText.sectionTitle.copyWith(
                fontSize: 26,
                color: Colors.white,
              ),
            ),
          ),
          if (isPrankMode &&
              naturalOptionLabel != null &&
              naturalOptionLabel != optionLabel) ...[
            const SizedBox(height: 12),
            Text(
              l10n.t(
                'spinWheelPrankResultShifted',
                {
                  'natural': naturalOptionLabel!,
                  'target': optionLabel,
                },
              ),
              style: GameUiText.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
