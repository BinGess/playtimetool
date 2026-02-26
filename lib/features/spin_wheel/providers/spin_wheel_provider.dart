import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wheel_segment.dart';

enum SpinPhase { idle, spinning, result }

class SpinWheelState {
  const SpinWheelState({
    required this.config,
    this.angle = 0.0,
    this.phase = SpinPhase.idle,
    this.resultIndex,
    this.angularVelocity = 0.0,
  });

  final WheelConfig config;
  final double angle; // radians
  final SpinPhase phase;
  final int? resultIndex;
  final double angularVelocity;

  SpinWheelState copyWith({
    WheelConfig? config,
    double? angle,
    SpinPhase? phase,
    int? resultIndex,
    double? angularVelocity,
  }) {
    return SpinWheelState(
      config: config ?? this.config,
      angle: angle ?? this.angle,
      phase: phase ?? this.phase,
      resultIndex: resultIndex ?? this.resultIndex,
      angularVelocity: angularVelocity ?? this.angularVelocity,
    );
  }

  WheelSegment? get resultSegment =>
      resultIndex != null ? config.segments[resultIndex!] : null;
}

class SpinWheelNotifier extends StateNotifier<SpinWheelState> {
  SpinWheelNotifier()
      : super(SpinWheelState(config: WheelPresets.dinner));

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  int _lastSegmentIndex = -1;
  Function(int)? onSegmentCross; // callback to trigger haptic

  static const double _friction = 0.985; // per frame at 60fps
  static const double _minVelocity = 0.02; // rad/s to stop

  void initTicker(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    // Exponential friction decay per frame
    var vel = state.angularVelocity * pow(_friction, dt * 60).toDouble();

    var angle = (state.angle + vel * dt) % (2 * pi);
    if (angle < 0) angle += 2 * pi;

    // Detect segment crossing for haptic
    final seg = _angleToSegmentIndex(angle);
    if (seg != _lastSegmentIndex) {
      _lastSegmentIndex = seg;
      onSegmentCross?.call(vel.abs().toInt());
    }

    if (vel.abs() < _minVelocity) {
      _ticker?.stop();
      _lastTick = Duration.zero;
      _resolveResult(angle);
    } else {
      state = state.copyWith(angle: angle, angularVelocity: vel);
    }
  }

  /// Called from gesture: linear px/s velocity → angular velocity
  void startSpin(double linearVelocity, double wheelRadius) {
    if (state.config.segments.isEmpty) return;
    _lastTick = Duration.zero;

    var angVel = linearVelocity / wheelRadius;
    // Cap to reasonable range
    angVel = angVel.clamp(-25.0, 25.0);
    // Minimum spin
    if (angVel.abs() < 3.0) angVel = angVel.sign * 3.0;

    state = state.copyWith(
      angularVelocity: angVel,
      phase: SpinPhase.spinning,
      resultIndex: null,
    );
    _ticker?.stop();
    _ticker?.start();
  }

  void _resolveResult(double finalAngle) {
    final idx = _angleToSegmentIndex(finalAngle);
    final effectiveIdx = _applyPrankBias(idx);

    state = state.copyWith(
      angle: finalAngle,
      angularVelocity: 0,
      phase: SpinPhase.result,
      resultIndex: effectiveIdx,
    );
  }

  int _angleToSegmentIndex(double angle) {
    final segments = state.config.segments;
    if (segments.isEmpty) return 0;
    final total = state.config.totalWeight;
    double cumulative = 0.0;
    // Wheel starts at top (-pi/2), pointer is fixed at top
    final normalizedAngle = ((-angle) % (2 * pi) + 2 * pi) % (2 * pi);

    for (int i = 0; i < segments.length; i++) {
      final sweep = (segments[i].weight / total) * 2 * pi;
      cumulative += sweep;
      if (normalizedAngle < cumulative) return i;
    }
    return segments.length - 1;
  }

  /// In prank mode, slightly reweight segments away from heavy-weight items
  int _applyPrankBias(int naturalIdx) {
    if (!state.config.isPrankMode) return naturalIdx;
    // In prank mode, find segment with lowest weight and steer toward it
    final segments = state.config.segments;
    final minWeight =
        segments.map((s) => s.weight).reduce(min);
    final lowWeightIdx =
        segments.indexWhere((s) => s.weight == minWeight);

    // 30% chance to redirect to lowest-weight segment
    if (Random().nextDouble() < 0.3) return lowWeightIdx;
    return naturalIdx;
  }

  void loadConfig(WheelConfig config) {
    _ticker?.stop();
    state = SpinWheelState(config: config);
  }

  void togglePrankMode() {
    state = state.copyWith(
      config: state.config.copyWith(isPrankMode: !state.config.isPrankMode),
    );
  }

  void dismissResult() {
    state = state.copyWith(phase: SpinPhase.idle, resultIndex: null);
  }

  // --- Custom editing ---
  void addSegment(WheelSegment segment) {
    final updated = [...state.config.segments, segment];
    state = state.copyWith(
      config: state.config.copyWith(segments: updated, name: '自定义'),
    );
  }

  void updateSegment(int index, WheelSegment segment) {
    final updated = [...state.config.segments];
    updated[index] = segment;
    state = state.copyWith(
      config: state.config.copyWith(segments: updated, name: '自定义'),
    );
  }

  void removeSegment(int index) {
    if (state.config.segments.length <= 2) return; // minimum 2 items
    final updated = [...state.config.segments]..removeAt(index);
    state = state.copyWith(
      config: state.config.copyWith(segments: updated, name: '自定义'),
    );
  }

  void reorderSegments(int oldIndex, int newIndex) {
    final updated = [...state.config.segments];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(
      config: state.config.copyWith(segments: updated, name: '自定义'),
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

final spinWheelProvider = StateNotifierProvider.autoDispose<SpinWheelNotifier,
    SpinWheelState>(
  (ref) => SpinWheelNotifier(),
);
