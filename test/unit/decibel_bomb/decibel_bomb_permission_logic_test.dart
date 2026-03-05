import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:playtimetool/features/decibel_bomb/logic/decibel_bomb_permission_logic.dart';

void main() {
  group('DecibelBombPermissionLogic', () {
    test('granted starts game directly', () {
      final action = resolveMicrophoneAction(PermissionStatus.granted);
      expect(action, MicrophoneAction.startGame);
    });

    test('restricted or permanentlyDenied should jump settings', () {
      expect(
        resolveMicrophoneAction(PermissionStatus.restricted),
        MicrophoneAction.openSettings,
      );
      expect(
        resolveMicrophoneAction(PermissionStatus.permanentlyDenied),
        MicrophoneAction.openSettings,
      );
    });

    test('denied should request again', () {
      final action = resolveMicrophoneAction(PermissionStatus.denied);
      expect(action, MicrophoneAction.requestPermission);
    });
  });
}
