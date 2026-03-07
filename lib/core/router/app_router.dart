import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/hub/hub_screen.dart';
import '../../features/finger_picker/finger_picker_screen.dart';
import '../../features/spin_wheel/spin_wheel_screen.dart';
import '../../features/number_bomb/number_bomb_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/party_plus/bomb_pass_screen.dart';
import '../../features/party_plus/left_right_react_screen.dart';
import '../../features/party_plus/bio_detector_screen.dart';
import '../../features/gravity_balance/gravity_balance_screen.dart';
import '../../features/gravity_balance/gravity_balance_prep_screen.dart';
import '../../features/gravity_balance/logic/gravity_balance_logic.dart';
import '../../shared/services/penalty_service.dart';
import '../../features/decibel_bomb/decibel_bomb_screen.dart';

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
      path: '/games/pass-bomb',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BombPassScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/games/left-right',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LeftRightReactScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/games/bio-detector',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BioDetectorScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/games/gravity-balance',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const GravityBalancePrepScreen(),
        transitionsBuilder: _fadeSlideTransition,
      ),
    ),
    GoRoute(
      path: '/games/gravity-balance/play',
      pageBuilder: (_, state) {
        final difficulty = parseGravityBalanceDifficulty(
          state.uri.queryParameters['difficulty'],
        );
        final participantCount = parseGravityBalanceParticipantCount(
          state.uri.queryParameters['players'],
        );
        final penaltyPreset = parsePenaltyPreset(
          scene: state.uri.queryParameters['penaltyScene'],
          intensity: state.uri.queryParameters['penaltyIntensity'],
        );
        return CustomTransitionPage(
          key: state.pageKey,
          child: GravityBalanceScreen(
            difficulty: difficulty,
            participantCount: participantCount,
            penaltyPreset: penaltyPreset,
          ),
          transitionsBuilder: _fadeSlideTransition,
        );
      },
    ),
    GoRoute(
      path: '/games/decibel-bomb',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DecibelBombScreen(),
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
    GoRoute(
      path: '/settings/about',
      pageBuilder: (_, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const AboutScreen(),
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
