import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/haptics/haptic_service.dart';
import '../../shared/widgets/glass_container.dart';
import 'models/bomb_state.dart';
import 'providers/number_bomb_provider.dart';

class NumberBombScreen extends ConsumerStatefulWidget {
  const NumberBombScreen({super.key});

  @override
  ConsumerState<NumberBombScreen> createState() => _NumberBombScreenState();
}

class _NumberBombScreenState extends ConsumerState<NumberBombScreen>
    with TickerProviderStateMixin {
  late AnimationController _bombPulseController;
  late AnimationController _flashController;
  late AnimationController _explosionController;
  late Animation<double> _bombPulse;
  late Animation<double> _flashAnim;
  late Animation<double> _explosionAnim;

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

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _flashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_flashController);

    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _explosionAnim =
        Tween<double>(begin: 0.0, end: 1.0).animate(_explosionController);
  }

  @override
  void dispose() {
    _bombPulseController.dispose();
    _flashController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(numberBombProvider);
    final notifier = ref.read(numberBombProvider.notifier);

    ref.listen(numberBombProvider, (prev, next) {
      if (next.lastGuessInvalid && !(prev?.lastGuessInvalid ?? false)) {
        _flashController.reset();
        _flashController.forward();
      }
      if (next.phase == BombPhase.explosion &&
          prev?.phase != BombPhase.explosion) {
        _explosionController.reset();
        _explosionController.forward();
      }
    });

    final bgColor = Color.lerp(
      AppColors.bombBlueDark,
      AppColors.bombRedDark,
      state.pressureRatio,
    )!;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_flashAnim, _explosionAnim]),
        builder: (_, child) {
          Color bg = bgColor;
          if (_flashAnim.value > 0) {
            bg = Color.lerp(bgColor, AppColors.bombRed.withAlpha(180),
                _flashAnim.value)!;
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            color: bg,
            child: child,
          );
        },
        child: Stack(
          children: [
            // Red breathing overlay (pressure escalation)
            if (state.phase == BombPhase.playing)
              AnimatedBuilder(
                animation: _bombPulse,
                builder: (_, __) => Opacity(
                  opacity:
                      state.pressureRatio * 0.15 * (1 - _bombPulse.value),
                  child: Container(color: AppColors.bombRed),
                ),
              ),

            SafeArea(
              child: state.phase == BombPhase.setup
                  ? _SetupView(onStart: notifier.startGame)
                  : state.phase == BombPhase.playing
                      ? _PlayingView(
                          state: state,
                          notifier: notifier,
                          bombPulse: _bombPulse,
                        )
                      : const SizedBox.shrink(),
            ),

            // Explosion overlay
            if (state.phase == BombPhase.explosion)
              _ExplosionOverlay(
                anim: _explosionAnim,
                punishmentText: state.punishmentText,
                onReset: notifier.reset,
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
      ),
    );
  }
}

class _SetupView extends StatefulWidget {
  const _SetupView({required this.onStart});

  final void Function({int min, int max}) onStart;

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  // Preset options: (label, min, max)
  static const _presets = [
    ('1 – 50', 1, 50),
    ('1 – 100', 1, 100),
    ('1 – 500', 1, 500),
    ('自定义', 0, 0),
  ];

  int _selectedPreset = 1; // default: 1–100
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Back button row
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios,
                  color: AppColors.textDim, size: 20),
            ),
          ),
          const Spacer(flex: 2),
          const Text(
            '数字炸弹',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'NUMBER BOMB',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              letterSpacing: 4,
            ),
          ),
          const Spacer(flex: 2),

          // Range picker
          const Text(
            '选择范围',
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_presets.length, (i) {
              final active = i == _selectedPreset;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedPreset = i);
                    HapticService.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.bombRed.withAlpha(200)
                            : AppColors.textDim,
                        width: active ? 1.5 : 1,
                      ),
                      color: active
                          ? AppColors.bombRed.withAlpha(25)
                          : Colors.transparent,
                    ),
                    child: Text(
                      _presets[i].$1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active
                            ? AppColors.bombRed
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Custom range sliders
          if (_isCustom) ...[
            const SizedBox(height: 20),
            _RangeRow(
              label: '最小值',
              value: _customMin,
              min: 1,
              max: _customMax - 1,
              onChanged: (v) => setState(() => _customMin = v),
            ),
            const SizedBox(height: 8),
            _RangeRow(
              label: '最大值',
              value: _customMax,
              min: _customMin + 1,
              max: 9999,
              onChanged: (v) => setState(() => _customMax = v),
            ),
          ],

          const SizedBox(height: 20),
          // Current range display
          Text(
            '$_effectiveMin  —  $_effectiveMax',
            style: TextStyle(
              color: AppColors.bombRed.withAlpha(200),
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: 2,
            ),
          ),

          const Spacer(flex: 3),

          // Start button
          GestureDetector(
            onTap: () => widget.onStart(min: _effectiveMin, max: _effectiveMax),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppColors.bombRed.withAlpha(150)),
                color: AppColors.bombRed.withAlpha(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bombRed.withAlpha(60),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Text(
                '开始游戏',
                style: TextStyle(
                  color: AppColors.bombRed,
                  fontSize: 18,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
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
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
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
            style: const TextStyle(
                color: AppColors.bombRed, fontSize: 14),
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
  });

  final BombState state;
  final NumberBombNotifier notifier;
  final Animation<double> bombPulse;

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
                    color: AppColors.textDim, size: 20),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => notifier.reset(),
                child: const Text(
                  '重置',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
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
        const Text(
          '安全区间',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            letterSpacing: 3,
          ),
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
              color: AppColors.bombRed.withAlpha(
                  (60 + 60 * state.pressureRatio).round()),
              shadows: [
                Shadow(
                  color: AppColors.bombRed.withAlpha(
                      (120 * state.pressureRatio).round()),
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
              state.currentInput.isEmpty ? '输入数字' : state.currentInput,
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
                  : Colors.white.withAlpha(
                      (30 + 180 * _pressAnim.value).round()),
              width: 1,
            ),
            color: Colors.white.withAlpha(
                (widget.isConfirm ? 50 : 15) +
                    (20 * _pressAnim.value).round()),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color:
                    widget.isConfirm ? AppColors.bombRed : Colors.white,
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
    required this.anim,
    required this.punishmentText,
    required this.onReset,
  });

  final Animation<double> anim;
  final String punishmentText;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
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

            // Punishment card
            if (t > 0.6)
              Opacity(
                opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                child: Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 32),
                    borderRadius: BorderRadius.circular(28),
                    borderColor: AppColors.bombRed.withAlpha(120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '💥  惩罚',
                          style: TextStyle(
                            color: AppColors.bombRed,
                            fontSize: 13,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          punishmentText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: onReset,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: AppColors.bombRed.withAlpha(120)),
                            ),
                            child: const Text(
                              '再来一局',
                              style: TextStyle(
                                color: AppColors.bombRed,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      final color =
          Color.lerp(AppColors.bombRed, Colors.orange, colorT)!;

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
