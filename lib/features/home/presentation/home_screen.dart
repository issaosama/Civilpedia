import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../localization/ar.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _lastBackPress;

  bool get _isAtShellRoot {
    final location = GoRouterState.of(context).uri.toString();
    return location == '/home' || location == '/tools' || location == '/saved' || location == '/profile';
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(Ar.exitConfirm),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;
    debugPrint('[Navigation] ${router.routerDelegate.currentConfiguration}');

    return PopScope(
      canPop: !_isAtShellRoot,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBottomNav.withValues(alpha: 0.85)
                      : AppColors.surfaceWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.5)
                        : AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : DesignTokens.cardShadow(AppColors.cardShadow),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, Ar.home, theme, currentIndex),
                    _buildNavItem(1, Icons.build_outlined, Icons.build, Ar.tools, theme, currentIndex),
                    _buildNavItem(2, Icons.bookmark_outline, Icons.bookmark, Ar.saved, theme, currentIndex),
                    _buildNavItem(3, Icons.person_outline, Icons.person, Ar.profile, theme, currentIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, ThemeData theme, int currentIndex) {
    final isSelected = currentIndex == index;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = AppColors.primary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            widget.navigationShell.goBranch(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? activeColor
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
