import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/language_provider.dart';
import '../../../data/local/preferences_helper.dart';
import '../../../core/location/baghdad_area.dart';
import '../../../features/profile/domain/user_profile.dart';
import '../../../features/profile/presentation/providers/user_profile_provider.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';

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
    final isArabic = context.watch<LanguageProvider>().isArabic;
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.engineering, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? Ar.splashSubtitle : En.splashSubtitle,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
