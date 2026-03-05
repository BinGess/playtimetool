import 'package:permission_handler/permission_handler.dart';

enum MicrophoneAction {
  startGame,
  requestPermission,
  openSettings,
}

MicrophoneAction resolveMicrophoneAction(PermissionStatus status) {
  if (status.isGranted) {
    return MicrophoneAction.startGame;
  }
  if (status.isRestricted || status.isPermanentlyDenied) {
    return MicrophoneAction.openSettings;
  }
  return MicrophoneAction.requestPermission;
}
