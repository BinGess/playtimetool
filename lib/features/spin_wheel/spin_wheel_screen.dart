import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../core/audio/audio_service.dart';
import '../../core/constants/app_sounds.dart';
import '../../shared/widgets/glass_container.dart';
import 'models/wheel_segment.dart';
import 'providers/spin_wheel_provider.dart';
import 'painters/wheel_painter.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  late AnimationController _resultController;
  late Animation<double> _resultAnim;

  double _lastDragAngle = 0;
  double _dragVelocity = 0;

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
    final state = ref.watch(spinWheelProvider);
    final notifier = ref.read(spinWheelProvider.notifier);
    final screenH = MediaQuery.sizeOf(context).height;
    final wheelSize = MediaQuery.sizeOf(context).width * 0.88;

    ref.listen(spinWheelProvider, (prev, next) {
      if (prev?.phase != SpinPhase.result && next.phase == SpinPhase.result) {
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
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios,
                            color: AppColors.textDim, size: 20),
                      ),
                      const Spacer(),
                      // Edit button
                      GestureDetector(
                        onTap: () => _showEditorSheet(context, state, notifier),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.textDim),
                          ),
                          child: const Text(
                            '✏  编辑',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ModeToggle(
                        isPrank: state.config.isPrankMode,
                        onToggle: notifier.togglePrankMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Wheel area
                SizedBox(
                  height: screenH * 0.52,
                  child: GestureDetector(
                    onPanStart: (d) {
                      _lastDragAngle = _angleFrom(context, d.globalPosition);
                      _dragVelocity = 0;
                    },
                    onPanUpdate: (d) {
                      final current = _angleFrom(context, d.globalPosition);
                      final delta = current - _lastDragAngle;
                      _dragVelocity = delta * 60;
                      _lastDragAngle = current;
                      ref.read(spinWheelProvider.notifier).dismissResult();
                    },
                    onPanEnd: (d) {
                      final vel = d.velocity.pixelsPerSecond.distance;
                      final sign = _dragVelocity.sign;
                      final radius = wheelSize / 2;
                      notifier.startSpin(vel * sign, radius);
                    },
                    child: AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, __) => Center(
                        child: CustomPaint(
                          painter: WheelPainter(
                            segments: state.config.segments,
                            totalWeight: state.config.totalWeight,
                            angle: state.angle,
                            accentColor: AppColors.wheelOrange,
                            glowIntensity: _glowAnim.value,
                            speed: state.angularVelocity.abs(),
                          ),
                          size: Size(wheelSize, wheelSize),
                        ),
                      ),
                    ),
                  ),
                ),

                // Template selector
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: WheelPresets.all.length,
                    itemBuilder: (_, i) {
                      final preset = WheelPresets.all[i];
                      final active = state.config.name == preset.name;
                      return GestureDetector(
                        onTap: () {
                          notifier.loadConfig(preset);
                          HapticService.lightImpact();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.wheelOrange
                                  : AppColors.textDim,
                              width: active ? 1.5 : 1,
                            ),
                            color: active
                                ? AppColors.wheelOrange.withAlpha(20)
                                : Colors.transparent,
                          ),
                          child: Text(
                            preset.name,
                            style: TextStyle(
                              color: active
                                  ? AppColors.wheelOrange
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Hint
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    '滑动旋转  •  ${state.config.name}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Result overlay
          if (state.phase == SpinPhase.result && state.resultSegment != null)
            _ResultOverlay(
              segment: state.resultSegment!,
              animation: _resultAnim,
              onDismiss: notifier.dismissResult,
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

  void _showEditorSheet(BuildContext ctx, SpinWheelState state,
      SpinWheelNotifier notifier) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WheelEditorSheet(
        config: state.config,
        notifier: notifier,
      ),
    );
  }
}

// ─────────────────────────── Editor bottom sheet ───────────────────────────

class _WheelEditorSheet extends ConsumerStatefulWidget {
  const _WheelEditorSheet({
    required this.config,
    required this.notifier,
  });

  final WheelConfig config;
  final SpinWheelNotifier notifier;

  @override
  ConsumerState<_WheelEditorSheet> createState() => _WheelEditorSheetState();
}

class _WheelEditorSheetState extends ConsumerState<_WheelEditorSheet> {
  static const _paletteColors = [
    Color(0xFFFF4444), Color(0xFFFF8C00), Color(0xFFFFE000),
    Color(0xFF44FF88), Color(0xFF00FFFF), Color(0xFF44AAFF),
    Color(0xFF9B00FF), Color(0xFFFF00FF), Color(0xFFFF6B35),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch live state for real-time segment list updates
    final liveSegments =
        ref.watch(spinWheelProvider).config.segments;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
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
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    '编辑转盘',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _addSegmentDialog(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.wheelOrange.withAlpha(30),
                        border: Border.all(
                          color: AppColors.wheelOrange.withAlpha(150),
                        ),
                      ),
                      child: const Text(
                        '＋ 添加',
                        style: TextStyle(
                          color: AppColors.wheelOrange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            // Segment list (reorderable)
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: liveSegments.length,
                onReorder: widget.notifier.reorderSegments,
                itemBuilder: (_, i) {
                  final seg = liveSegments[i];
                  return _SegmentTile(
                    key: ValueKey('$i-${seg.label}'),
                    segment: seg,
                    index: i,
                    canDelete: liveSegments.length > 2,
                    onEdit: () => _editSegmentDialog(context, i, seg),
                    onDelete: () => widget.notifier.removeSegment(i),
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
    _showSegmentDialog(
      ctx,
      title: '添加选项',
      initialLabel: '',
      initialColor: _paletteColors[0],
      onConfirm: (label, color) {
        if (label.isNotEmpty) {
          widget.notifier
              .addSegment(WheelSegment(label: label, color: color));
          HapticService.lightImpact();
        }
      },
    );
  }

  void _editSegmentDialog(BuildContext ctx, int index, WheelSegment seg) {
    _showSegmentDialog(
      ctx,
      title: '编辑选项',
      initialLabel: seg.label,
      initialColor: seg.color,
      onConfirm: (label, color) {
        if (label.isNotEmpty) {
          widget.notifier.updateSegment(
              index, WheelSegment(label: label, color: color));
          HapticService.lightImpact();
        }
      },
    );
  }

  void _showSegmentDialog(
    BuildContext ctx, {
    required String title,
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
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                autofocus: true,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: '选项名称',
                  hintStyle:
                      const TextStyle(color: AppColors.textDim),
                  counterStyle:
                      const TextStyle(color: AppColors.textDim),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.wheelOrange.withAlpha(100),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.wheelOrange),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('颜色',
                  style: TextStyle(
                      color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paletteColors.map((c) {
                  final selected = picked == c;
                  return GestureDetector(
                    onTap: () => setS(() => picked = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
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
              child: const Text('取消',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                onConfirm(textCtrl.text.trim(), picked);
              },
              child: const Text('确定',
                  style: TextStyle(color: AppColors.wheelOrange)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
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
            const Icon(Icons.drag_handle,
                color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Mode toggle ───────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isPrank, required this.onToggle});

  final bool isPrank;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrank
                ? AppColors.bombRed.withAlpha(150)
                : AppColors.textDim,
          ),
          color: isPrank
              ? AppColors.bombRed.withAlpha(20)
              : Colors.transparent,
        ),
        child: Text(
          isPrank ? '😈 恶搞' : '⚖️ 公平',
          style: TextStyle(
            color: isPrank ? AppColors.bombRed : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Result overlay ───────────────────────────

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.segment,
    required this.animation,
    required this.onDismiss,
  });

  final WheelSegment segment;
  final Animation<double> animation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.black.withAlpha(100),
          child: Center(
            child: ScaleTransition(
              scale: animation,
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 32),
                borderRadius: BorderRadius.circular(28),
                borderColor: segment.color.withAlpha(120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '结果',
                      style: TextStyle(
                        color: segment.color.withAlpha(180),
                        fontSize: 11,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      segment.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: segment.color.withAlpha(200),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '轻触任意位置继续',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
