import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/core/sensors/device_motion_service.dart';

void main() {
  test('tiltFromAccelerometer maps gravity x/y to pitch/roll radians', () {
    final flat = tiltFromAccelerometer(x: 0, y: 0, z: 9.81);
    expect(flat.pitch, closeTo(0, 1e-6));
    expect(flat.roll, closeTo(0, 1e-6));

    final rightTilt = tiltFromAccelerometer(x: -9.81, y: 0, z: 0);
    expect(rightTilt.roll, closeTo(pi / 2, 0.03));

    final forwardTilt = tiltFromAccelerometer(x: 0, y: 9.81, z: 0);
    expect(forwardTilt.pitch, closeTo(pi / 2, 0.03));
  });
}
