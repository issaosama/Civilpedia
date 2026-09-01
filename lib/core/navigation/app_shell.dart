import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../localization/ar.dart';
import '../../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'shell_content_insets.dart';

/// Metadata for one bottom-navigation destination of the application shell.
///
/// The order of [kShellDestinations] IS the branch index contract shared with
/// `StatefulShellRoute.indexedStack` in the app router. Adding a future
/// domain (Encyclopedia, Engineering Directory) means appending an entry here
/// and registering its branch builder in the router - never editing magic
/// integers scattered across the app.
class ShellDestination {
  final String route;

  /// Icon shown when the branch is not selected.
  final IconData icon;

  /// Icon shown when the branch is selected.
  final IconData activeIcon;

  final String label;

  const ShellDestination({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// The current, user-visible shell destinations.
///
/// W6.3 performs the real Bottom Navigation transition to the target shell:
/// Saved and Profile leave the visible bar (they remain routable as root
/// compatibility routes) and the freed slots are filled by Projects (M3 NAV-4)
/// and the Engineering Directory (M3 NAV-5). Exactly 5 destinations, in order.
/// The order of every entry is the branch-index contract shared with
/// `StatefulShellRoute.indexedStack` — never reorder casually.
const List<ShellDestination> kShellDestinations = [
  ShellDestination(
    route: AppRoutes.home,
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: Ar.home,
  ),
  ShellDestination(
    route: AppRoutes.encyclopedia,
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book,
    label: Ar.encyclopedia,
  ),
  ShellDestination(
    route: AppRoutes.tools,
    icon: Icons.build_outlined,
    activeIcon: Icons.build,
    label: Ar.tools,
  ),
  ShellDestination(
    route: AppRoutes.projects,
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder,
    label: Ar.checklistMyProjects,
  ),
  ShellDestination(
    route: AppRoutes.directory,
    icon: Icons.business_center_outlined,
    activeIcon: Icons.business_center,
    label: Ar.directory,
  ),
];

/// The Civilpedia application shell.
///
/// Owns navigation chrome only: the IndexedStack navigation shell host, the
/// floating bottom navigation bar built from [kShellDestinations], and the
/// double-back-to-exit behavior at any branch root. Dashboard/knowledge/tool
/// content belongs to the screens routed inside each branch (for example
/// `HomeMainScreen` for `/home`) - never to this widget.
///
/// Single source of truth for the floating bottom-navigation content
/// obstruction. The same metrics drive both the nav bar layout ([_navHeight],
/// [_navBottomMargin]) and the [ShellContentInsets] published to branch
/// content so screens can clear it without knowing any geometry details.
class AppShell extends StatefulWidget {
  /// Height of the floating bottom-navigation container.
  static const double _navHeight = 70;

  /// Bottom margin of the floating bottom-navigation container.
  static const double _navBottomMargin = 16;

  /// Persistent content obstruction from the screen bottom caused by the
  /// floating bottom navigation bar: its height plus its bottom margin.
  ///
  /// This does NOT include the device safe-area inset, which is handled
  /// separately by each screen via `MediaQuery.paddingOf(context).bottom`.
  static const double shellBottomObstruction =
      _navHeight + _navBottomMargin;
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  DateTime? _lastBackPress;

  bool get _isAtShellRoot {
    // Compare path only so that query parameters (e.g. /encyclopedia?q=...)
    // do not disable the shell-level double-back-to-exit behavior.
    final path = GoRouterState.of(context).uri.path;
    return kShellDestinations.any((destination) => destination.route == path);
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;

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
          child: ShellContentInsets(
            bottomObstruction: AppShell.shellBottomObstruction,
            child: Column(
              children: [
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            AppShell._navBottomMargin,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: AppShell._navHeight,
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
                    for (var i = 0; i < kShellDestinations.length; i++)
                      _buildNavItem(
                        index: i,
                        destination: kShellDestinations[i],
                        theme: theme,
                        currentIndex: currentIndex,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required ShellDestination destination,
    required ThemeData theme,
    required int currentIndex,
  }) {
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
                  isSelected ? destination.activeIcon : destination.icon,
                  color: isSelected
                      ? activeColor
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? activeColor
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
