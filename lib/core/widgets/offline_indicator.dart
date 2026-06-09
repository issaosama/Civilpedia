import 'package:flutter/material.dart';
import '../../localization/ar.dart';

class OfflineIndicator extends StatelessWidget {
  final bool isOffline;

  const OfflineIndicator({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.orange.shade700,
      child: Text(
        Ar.offline,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
