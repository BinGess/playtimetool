import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../features/gravity_balance/logic/gravity_balance_logic.dart';

const EventChannel _deviceMotionChannel =
    EventChannel('playtimetool/device_motion');

final deviceTiltProvider = StreamProvider<DeviceTilt>((ref) {
  final accelerometerStream = accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  ).map(
    (event) => tiltFromAccelerometer(
      x: event.x,
      y: event.y,
      z: event.z,
    ),
  );

  if (!Platform.isIOS) {
    return accelerometerStream;
  }

  final controller = StreamController<DeviceTilt>();
  StreamSubscription<dynamic>? primarySub;
  StreamSubscription<DeviceTilt>? fallbackSub;
  Timer? watchdog;
  var hasPrimaryEvent = false;

  void startFallback() {
    if (fallbackSub != null) return;
    primarySub?.cancel();
    fallbackSub = accelerometerStream.listen(
      controller.add,
      onError: controller.addError,
    );
  }

  watchdog = Timer(const Duration(milliseconds: 800), () {
    if (!hasPrimaryEvent) {
      startFallback();
    }
  });

  primarySub = _deviceMotionChannel.receiveBroadcastStream().listen(
    (event) {
      hasPrimaryEvent = true;
      watchdog?.cancel();
      controller.add(_mapNativeDeviceMotion(event));
    },
    onError: (_) {
      if (!hasPrimaryEvent) {
        startFallback();
      }
    },
    onDone: () {
      if (!hasPrimaryEvent) {
        startFallback();
      }
    },
  );

  ref.onDispose(() async {
    watchdog?.cancel();
    await primarySub?.cancel();
    await fallbackSub?.cancel();
    await controller.close();
  });

  return controller.stream;
});

DeviceTilt _mapNativeDeviceMotion(dynamic event) {
  if (event is! Map) {
    return const DeviceTilt(pitch: 0, roll: 0);
  }

  final pitch = (event['pitch'] as num?)?.toDouble() ?? 0;
  final roll = (event['roll'] as num?)?.toDouble() ?? 0;
  return DeviceTilt(pitch: pitch, roll: roll);
}

DeviceTilt tiltFromAccelerometer({
  required double x,
  required double y,
  required double z,
}) {
  final g = sqrt(x * x + y * y + z * z);
  if (g < 0.1) {
    return const DeviceTilt(pitch: 0, roll: 0);
  }

  final nx = (x / g).clamp(-1.0, 1.0);
  final ny = (y / g).clamp(-1.0, 1.0);

  return DeviceTilt(
    pitch: asin(ny),
    roll: asin(-nx),
  );
}
