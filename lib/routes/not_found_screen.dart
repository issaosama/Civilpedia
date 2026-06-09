import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../localization/ar.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(
                '404',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                Ar.pageNotFound,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                Ar.pageNotFoundMsg,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/home');
                },
                icon: const Icon(Icons.home),
                label: const Text(Ar.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
