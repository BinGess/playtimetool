import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Exposes gyroscope event stream. Gracefully degrades if no sensor.
final gyroscopeProvider = StreamProvider<GyroscopeEvent>((ref) {
  return gyroscopeEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  ).handleError((_) {});
});
