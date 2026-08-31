import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/spacing.dart';

/// InheritedWidget that publishes the AppShell's persistent bottom-navigation
/// content obstruction.
///
/// Only descendants of the [AppShell] widget receive a non-null value.
/// Root-navigator routes do NOT have this ancestor and naturally receive `null`
/// via [maybeOf].
///
/// The [bottomObstruction] value represents the physical distance from the
/// screen bottom edge to the top of the visible scroll region. It accounts for
/// the floating navigation bar's height and its bottom margin, but does NOT
/// include the device safe-area inset (which is a separate concern managed by
/// each screen if needed).
class ShellContentInsets extends InheritedWidget {
  /// Distance from screen bottom to the top of the visible content region,
  /// caused by the persistent floating bottom navigation.
  final double bottomObstruction;

  const ShellContentInsets({
    super.key,
    required this.bottomObstruction,
    required super.child,
  });

  /// Returns the [ShellContentInsets] if the widget tree is inside the
  /// AppShell, or `null` if it is not (e.g. a root-navigator route).
  static ShellContentInsets? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellContentInsets>();
  }

  /// Returns the [ShellContentInsets] — asserts if called outside the
  /// AppShell. Prefer [maybeOf] for widgets that may run in both contexts.
  static ShellContentInsets of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'ShellContentInsets not found in widget tree');
    return result!;
  }

  @override
  bool updateShouldNotify(ShellContentInsets oldWidget) =>
      bottomObstruction != oldWidget.bottomObstruction;
}

/// Computes the bottom padding a scrollable screen needs so its final content
/// item clears the persistent shell navigation with normal visual breathing
/// room.
///
/// Works correctly in both contexts:
///
/// - **Inside AppShell** (shell route): uses [ShellContentInsets] obstruction,
///   which is always >= device safe-area inset.
/// - **Outside AppShell** (root route): [ShellContentInsets] is absent, so the
///   device safe-area inset is used directly.
///
/// The formula is:
/// ```dart
/// max(shellObstruction, deviceInset) + breathingRoom
/// ```
///
/// Using `max` (not sum) avoids double-counting because both values are
/// measured from the physical screen bottom.
double shellSafeBottomPadding(
  BuildContext context, {
  double breathingRoom = AppSpacing.lg,
}) {
  final shellObstruction =
      ShellContentInsets.maybeOf(context)?.bottomObstruction ?? 0;
  final deviceInset = MediaQuery.paddingOf(context).bottom;
  return math.max(shellObstruction, deviceInset) + breathingRoom;
}
