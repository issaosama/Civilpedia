import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/ar.dart';
import '../theme/app_colors.dart';

class AsyncValueWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final Widget Function() onData;
  final Widget Function()? onLoading;
  final Widget Function(String error, VoidCallback? onRetry)? onError;
  final Widget Function()? onEmpty;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    this.isLoading = false,
    this.error,
    this.isEmpty = false,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return onLoading?.call() ??
          const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return onError?.call(error!, onRetry) ??
          _defaultError(context, error!, onRetry);
    }

    if (isEmpty) {
      return onEmpty?.call() ?? _defaultEmpty(context);
    }

    return onData();
  }

  Widget _defaultError(BuildContext context, String msg, VoidCallback? retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              msg,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            if (retry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  retry();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(Ar.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              Ar.emptyHere,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
