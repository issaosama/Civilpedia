import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/ar.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message ?? Ar.errorOccurred,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh),
                label: const Text(Ar.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String? message;

  const EmptyStateWidget({super.key, this.icon = Icons.inbox_outlined, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message ?? Ar.emptyHere,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
