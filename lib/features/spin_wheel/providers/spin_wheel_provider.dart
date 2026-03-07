import 'dart:convert';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wheel_segment.dart';

enum SpinPhase { idle, spinning, result }

class SpinWheelState {
  const SpinWheelState({
    required this.templates,
    required this.selectedTemplateId,
    this.angle = 0.0,
    this.phase = SpinPhase.idle,
    this.resultIndex,
    this.naturalResultIndex,
    this.angularVelocity = 0.0,
    this.liveSegmentIndex = 0,
    this.prankTargetIndex,
    this.prankBiasProgress = 0.0,
  });

  final List<WheelConfig> templates;
  final String selectedTemplateId;
  final double angle; // radians
  final SpinPhase phase;
  final int? resultIndex;
  final int? naturalResultIndex;
  final double angularVelocity;
  final int? liveSegmentIndex;
  final int? prankTargetIndex;
  final double prankBiasProgress;

  WheelConfig get config {
    for (final template in templates) {
      if (template.id == selectedTemplateId) {
        return template;
      }
    }
    return templates.first;
  }

  SpinWheelState copyWith({
    List<WheelConfig>? templates,
    String? selectedTemplateId,
    double? angle,
    SpinPhase? phase,
    int? resultIndex,
    int? naturalResultIndex,
    double? angularVelocity,
    int? liveSegmentIndex,
    int? prankTargetIndex,
    double? prankBiasProgress,
  }) {
    return SpinWheelState(
      templates: templates ?? this.templates,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      angle: angle ?? this.angle,
      phase: phase ?? this.phase,
      resultIndex: resultIndex ?? this.resultIndex,
      naturalResultIndex: naturalResultIndex ?? this.naturalResultIndex,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      liveSegmentIndex: liveSegmentIndex ?? this.liveSegmentIndex,
      prankTargetIndex: prankTargetIndex ?? this.prankTargetIndex,
      prankBiasProgress: prankBiasProgress ?? this.prankBiasProgress,
    );
  }

  WheelSegment? get resultSegment =>
      resultIndex != null ? config.segments[resultIndex!] : null;
}

class SpinWheelNotifier extends StateNotifier<SpinWheelState> {
  SpinWheelNotifier()
      : super(
          SpinWheelState(
            templates: WheelPresets.all,
            selectedTemplateId: WheelPresets.dinner.id,
          ),
        ) {
    _loadPersistedTemplates();
  }

  final _random = Random();
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  int _lastSegmentIndex = -1;
  Function(int)? onSegmentCross; // callback to trigger haptic

  static const _customTemplatesKey = 'spinWheelCustomTemplatesV1';
  static const _selectedTemplateKey = 'spinWheelSelectedTemplateId';

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

    var prankBiasProgress = 0.0;
    if (state.config.isPrankMode && state.prankTargetIndex != null) {
      prankBiasProgress = _prankGuideProgress(vel.abs());
      angle = _applyPrankGuidance(
        angle,
        state.prankTargetIndex!,
        vel.sign == 0 ? 1 : vel.sign,
        prankBiasProgress,
      );
    }

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
      state = state.copyWith(
        angle: angle,
        angularVelocity: vel,
        liveSegmentIndex: seg,
        prankBiasProgress: prankBiasProgress,
      );
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
      naturalResultIndex: null,
      liveSegmentIndex: _angleToSegmentIndex(state.angle),
      prankTargetIndex: state.config.isPrankMode ? _pickPrankTarget() : null,
      prankBiasProgress: 0,
    );
    _ticker?.stop();
    _ticker?.start();
  }

  void _resolveResult(double finalAngle) {
    final naturalIdx = _angleToSegmentIndex(finalAngle);
    final effectiveIdx = _applyPrankBias(naturalIdx);
    final settledAngle = effectiveIdx == naturalIdx
        ? finalAngle
        : _angleForSegmentCenter(effectiveIdx);

    state = state.copyWith(
      angle: settledAngle,
      angularVelocity: 0,
      phase: SpinPhase.result,
      resultIndex: effectiveIdx,
      naturalResultIndex: naturalIdx,
      liveSegmentIndex: effectiveIdx,
      prankBiasProgress: state.config.isPrankMode ? 1 : 0,
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

  double _prankGuideProgress(double speed) {
    final progress = (1 - (speed / 7.5)).clamp(0.0, 1.0);
    final eased = 1 - pow(1 - progress, 2).toDouble();
    return eased;
  }

  double _applyPrankGuidance(
    double angle,
    int targetIndex,
    double directionSign,
    double progress,
  ) {
    if (progress <= 0) return angle;
    final targetAngle = _angleForSegmentCenter(targetIndex);
    final delta = _directedAngleDelta(angle, targetAngle, directionSign);
    final cappedDelta = delta.clamp(-0.45, 0.45).toDouble();
    final pullFactor = 0.08 + progress * 0.24;
    final adjustedAngle = angle + cappedDelta * pullFactor;
    return _normalizeAngle(adjustedAngle);
  }

  double _directedAngleDelta(double from, double to, double directionSign) {
    final forward = ((to - from) % (2 * pi) + 2 * pi) % (2 * pi);
    if (directionSign >= 0) return forward;
    if (forward == 0) return 0;
    return forward - 2 * pi;
  }

  double _angleForSegmentCenter(int index) {
    final segments = state.config.segments;
    if (segments.isEmpty) return 0.0;

    final total = state.config.totalWeight;
    double cumulative = 0;
    for (int i = 0; i < segments.length; i++) {
      final sweep = (segments[i].weight / total) * 2 * pi;
      if (i == index) {
        final normalizedCenter = cumulative + sweep / 2;
        return _normalizeAngle(-normalizedCenter);
      }
      cumulative += sweep;
    }
    return 0.0;
  }

  double _normalizeAngle(double angle) {
    final normalized = angle % (2 * pi);
    return normalized < 0 ? normalized + 2 * pi : normalized;
  }

  int? _pickPrankTarget() {
    final segments = state.config.segments;
    if (segments.isEmpty) return null;

    final weights = segments.map((s) => s.weight).toList();
    final minW = weights.reduce(min);
    final maxW = weights.reduce(max);

    if (maxW - minW > 0.01) {
      final lowIndices = segments
          .asMap()
          .entries
          .where((entry) => (entry.value.weight - minW).abs() < 0.01)
          .map((entry) => entry.key)
          .toList();
      return lowIndices[_random.nextInt(lowIndices.length)];
    }

    final currentLive = state.liveSegmentIndex;
    final candidates =
        segments.asMap().keys.where((i) => i != currentLive).toList();
    if (candidates.isEmpty) return 0;
    return candidates[_random.nextInt(candidates.length)];
  }

  /// 恶搞模式：提前锁定一个目标，并在减速阶段把结果拖向该扇区
  int _applyPrankBias(int naturalIdx) {
    if (!state.config.isPrankMode) return naturalIdx;

    final segments = state.config.segments;
    if (segments.isEmpty) return naturalIdx;
    return state.prankTargetIndex ?? naturalIdx;
  }

  void loadConfig(WheelConfig config) {
    _ticker?.stop();
    state = SpinWheelState(
      templates: state.templates,
      selectedTemplateId: config.id,
    );
    _persistSelectedTemplateId(config.id);
  }

  void togglePrankMode() {
    state = state.copyWith(
      templates: _replaceTemplate(
        state.config.copyWith(isPrankMode: !state.config.isPrankMode),
      ),
    );
    _persistCustomTemplates();
  }

  void setPrankMode(bool isPrankMode) {
    if (state.config.isPrankMode == isPrankMode) return;
    state = state.copyWith(
      templates: _replaceTemplate(
        state.config.copyWith(isPrankMode: isPrankMode),
      ),
    );
    _persistCustomTemplates();
  }

  void dismissResult() {
    state = state.copyWith(
      phase: SpinPhase.idle,
      resultIndex: null,
      naturalResultIndex: null,
      prankTargetIndex: null,
      prankBiasProgress: 0,
      liveSegmentIndex: _angleToSegmentIndex(state.angle),
    );
  }

  Future<void> saveTemplate(
    WheelConfig template, {
    String? originalTemplateId,
  }) async {
    final templates = [...state.templates];
    final existingIndex = originalTemplateId == null
        ? -1
        : templates.indexWhere((item) => item.id == originalTemplateId);
    final templateId = existingIndex >= 0 && !templates[existingIndex].isBuiltIn
        ? originalTemplateId!
        : _nextTemplateId();

    final savedTemplate = template.copyWith(id: templateId);

    if (existingIndex >= 0 && !templates[existingIndex].isBuiltIn) {
      templates[existingIndex] = savedTemplate;
    } else {
      templates.add(savedTemplate);
    }

    _ticker?.stop();
    state = SpinWheelState(
      templates: templates,
      selectedTemplateId: savedTemplate.id,
    );
    await _persistCustomTemplates();
    await _persistSelectedTemplateId(savedTemplate.id);
  }

  Future<void> deleteTemplate(String templateId) async {
    final templateIndex =
        state.templates.indexWhere((template) => template.id == templateId);
    if (templateIndex < 0) return;

    final templateToDelete = state.templates[templateIndex];
    if (templateToDelete.isBuiltIn) return;

    final updatedTemplates =
        state.templates.where((template) => template.id != templateId).toList();
    final fallbackSelectedTemplateId = state.selectedTemplateId == templateId
        ? (updatedTemplates
                .any((template) => template.id == WheelPresets.dinner.id)
            ? WheelPresets.dinner.id
            : updatedTemplates.first.id)
        : state.selectedTemplateId;

    _ticker?.stop();
    state = SpinWheelState(
      templates: updatedTemplates,
      selectedTemplateId: fallbackSelectedTemplateId,
    );
    await _persistCustomTemplates();
    await _persistSelectedTemplateId(fallbackSelectedTemplateId);
  }

  List<WheelConfig> _replaceTemplate(WheelConfig updatedTemplate) {
    return state.templates
        .map((template) =>
            template.id == updatedTemplate.id ? updatedTemplate : template)
        .toList();
  }

  String _nextTemplateId() {
    return 'custom_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1000)}';
  }

  Future<void> _loadPersistedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTemplates = prefs.getString(_customTemplatesKey);
    final selectedTemplateId = prefs.getString(_selectedTemplateKey);

    List<WheelConfig> customTemplates = const [];
    if (storedTemplates != null && storedTemplates.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedTemplates);
        if (decoded is List) {
          customTemplates = decoded
              .whereType<Map>()
              .map(
                (item) => WheelConfig.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where((item) => item.segments.length >= 2)
              .toList();
        }
      } catch (_) {
        customTemplates = const [];
      }
    }

    final templates = [...WheelPresets.all, ...customTemplates];
    final resolvedSelectedTemplateId = templates.any(
      (template) => template.id == selectedTemplateId,
    )
        ? selectedTemplateId!
        : state.selectedTemplateId;

    state = state.copyWith(
      templates: templates,
      selectedTemplateId: resolvedSelectedTemplateId,
    );
  }

  Future<void> _persistCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final customTemplates = state.templates
        .where((template) => !template.isBuiltIn)
        .map((template) => template.toJson())
        .toList();
    await prefs.setString(_customTemplatesKey, jsonEncode(customTemplates));
  }

  Future<void> _persistSelectedTemplateId(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateKey, templateId);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}

final spinWheelProvider =
    StateNotifierProvider.autoDispose<SpinWheelNotifier, SpinWheelState>(
  (ref) => SpinWheelNotifier(),
);
