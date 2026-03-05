import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/gravity_balance/logic/gravity_balance_logic.dart';

const EventChannel _deviceMotionChannel =
    EventChannel('playtimetool/device_motion');

final deviceTiltProvider = StreamProvider<DeviceTilt>((ref) {
  if (!Platform.isIOS) {
    return Stream<DeviceTilt>.periodic(
      const Duration(milliseconds: 16),
      (_) => const DeviceTilt(pitch: 0, roll: 0),
    );
  }

  final stream = _deviceMotionChannel.receiveBroadcastStream().map((event) {
    if (event is! Map) {
      return const DeviceTilt(pitch: 0, roll: 0);
    }

    final pitch = (event['pitch'] as num?)?.toDouble() ?? 0;
    final roll = (event['roll'] as num?)?.toDouble() ?? 0;
    return DeviceTilt(pitch: pitch, roll: roll);
  });

  return stream.handleError((_) {
    // Keep UI alive even when native motion stream fails.
  });
});
