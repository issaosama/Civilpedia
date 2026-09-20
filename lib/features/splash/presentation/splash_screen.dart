import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../../core/services/logger_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/preferences_helper.dart';
import '../../../routes/app_routes.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import 'civilpedia_splash_animation.dart';

/// The router's initial surface beneath the production splash overlay.
///
/// It intentionally contains no branding or timing logic. The approved
/// [CivilpediaSplashAnimation] is installed once at the app root by
/// [ProductionSplashGate], allowing the real resolved route to mount beneath
/// it before the final fade.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.surfaceWhite);
  }
}

typedef StartupDestinationCallback = void Function(String route);
typedef StartupRoutePathReader = String Function();

/// Coordinates startup resolution with the approved production animation.
///
/// Startup work begins immediately and independently. Once resolved, the real
/// GoRouter destination is mounted beneath the animation. The animation can
/// only begin its final fade after that destination has painted at least one
/// frame, preventing an intermediate blank or duplicate splash route.
class ProductionSplashGate extends StatefulWidget {
  const ProductionSplashGate({
    required this.child,
    required this.startupReady,
    required this.currentRoutePath,
    required this.onDestinationResolved,
    super.key,
  });

  final Widget child;
  final Future<void> startupReady;
  final StartupRoutePathReader currentRoutePath;
  final StartupDestinationCallback onDestinationResolved;

  @override
  State<ProductionSplashGate> createState() => _ProductionSplashGateState();
}

class _ProductionSplashGateState extends State<ProductionSplashGate> {
  final ValueNotifier<bool> _destinationReady = ValueNotifier<bool>(false);
  bool _startupStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startupStarted) return;
    _startupStarted = true;
    unawaited(_resolveAndPrepareDestination());
  }

  Future<void> _resolveAndPrepareDestination() async {
    await widget.startupReady;
    if (!mounted) return;

    // A platform deep link or another legitimate router transition may have
    // replaced /splash while startup work was pending. Read the live router
    // state immediately before deciding whether this gate still owns startup
    // navigation; never overwrite a newer route.
    if (widget.currentRoutePath() == AppRoutes.splash) {
      final String destination;
      if (!PreferencesHelper.isOnboardingSeen) {
        destination = AppRoutes.onboarding;
      } else {
        final profile = context.read<UserProfileProvider>().profile;
        destination = profile == null || !profile.isProfileSetupComplete
            ? AppRoutes.profileSetup
            : AppRoutes.home;
      }

      widget.onDestinationResolved(destination);
      LoggerService.info('Splash → ${destination.substring(1)}');
    }

    // Let GoRouter build and paint the resolved destination underneath the
    // opaque splash before the approved final fade is allowed to start.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    _destinationReady.value = true;
  }

  @override
  void dispose() {
    _destinationReady.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CivilpediaSplashAnimation(
      revealReady: _destinationReady,
      destination: widget.child,
    );
  }
}
