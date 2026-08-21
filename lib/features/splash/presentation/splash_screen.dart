import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/logger_service.dart';
import '../../../data/local/preferences_helper.dart';
import '../../../core/location/baghdad_area.dart';
import '../../../features/profile/domain/user_profile.dart';
import '../../../features/profile/presentation/providers/user_profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppConstants.splashDuration);
    if (!mounted) return;
    if (!PreferencesHelper.isOnboardingSeen) {
      context.go('/onboarding');
      LoggerService.info('Splash → onboarding');
      return;
    }
    final profileProvider = context.read<UserProfileProvider>();
    await profileProvider.loadProfile();
    if (!mounted) return;
    final profile = profileProvider.profile;
    if (profile == null ||
        profile.userType == CivilUserType.generalUser ||
        profile.baghdadArea == BaghdadArea.unknown) {
      context.go('/profile-setup');
      LoggerService.info('Splash → profile-setup');
    } else {
      context.go('/home');
      LoggerService.info('Splash → home');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.82,
                      maxHeight: constraints.maxHeight * 0.6,
                    ),
                    child: Image.asset(
                      'assets/branding/splash_logo_display.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
