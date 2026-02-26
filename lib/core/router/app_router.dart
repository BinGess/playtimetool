import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/hub/hub_screen.dart';
import '../../features/finger_picker/finger_picker_screen.dart';
import '../../features/spin_wheel/spin_wheel_screen.dart';
import '../../features/number_bomb/number_bomb_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HubScreen(),
    ),
    GoRoute(
      path: '/finger',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const FingerPickerScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/wheel',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SpinWheelScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/bomb',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NumberBombScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
  ],
);

Widget _fadeSlideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    )),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}
