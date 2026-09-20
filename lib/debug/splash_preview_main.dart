import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/spacing.dart';
import '../features/splash/presentation/civilpedia_splash_animation.dart';

void main() {
  runApp(const SplashPreviewApp());
}

class SplashPreviewApp extends StatelessWidget {
  const SplashPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civilpedia Splash Preview',
      theme: AppTheme.lightTheme,
      home: const SplashPreviewScreen(),
    );
  }
}

class SplashPreviewScreen extends StatefulWidget {
  const SplashPreviewScreen({super.key});

  @override
  State<SplashPreviewScreen> createState() => _SplashPreviewScreenState();
}

class _SplashPreviewScreenState extends State<SplashPreviewScreen> {
  var _replaySignal = 0;
  var _completed = false;

  void _replay() {
    setState(() {
      _completed = false;
      _replaySignal++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CivilpediaSplashAnimation(
            replaySignal: _replaySignal,
            onCompleted: () {
              if (mounted) setState(() => _completed = true);
            },
            destination: const PreviewDestination(),
          ),
          if (kDebugMode && _completed)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: AppSpacing.padXl,
                  child: FilledButton.tonalIcon(
                    onPressed: _replay,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Replay'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PreviewDestination extends StatelessWidget {
  const PreviewDestination({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            margin: AppSpacing.hPadLg,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.huge,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.domain_rounded,
                  size: 40,
                  color: colorScheme.secondary,
                ),
                AppSpacing.gapLg,
                Text(
                  'Preview Destination',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapSm,
                Text(
                  'Stage 1 transition target',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
