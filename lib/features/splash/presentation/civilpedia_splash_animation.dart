import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Central timing authority for the isolated Civilpedia splash prototype.
class SplashMotionSpec {
  SplashMotionSpec._();

  static const int totalMilliseconds = 2890;
  static const Duration totalDuration = Duration(
    milliseconds: totalMilliseconds,
  );

  static const int backgroundOnlyEnd = 120;

  static const List<int> panelStartMilliseconds = [120, 185, 250, 315, 380];
  static const List<int> panelEndMilliseconds = [640, 705, 770, 835, 900];

  static const int settleStart = 900;
  static const int settleEnd = 1080;

  static const int accentStart = 1080;
  static const int accentEnd = 1400;

  static const int wordmarkStart = 1200;
  static const int wordmarkEnd = 1500;
  static const int taglineStart = 1350;
  static const int taglineEnd = 1650;

  static const int horizontalShimmerStart = 2000;
  static const int horizontalShimmerEnd = 2220;
  static const int verticalShimmerStart = 2220;
  static const int verticalShimmerEnd = 2440;
  static const int endpointGlintStart = 2440;
  static const int endpointGlintEnd = 2550;
  static const int traceFadeStart = 2550;
  static const int traceFadeEnd = 2670;
  static const int splashFadeStart = 2670;
  static const int splashFadeEnd = totalMilliseconds;
}

/// Stable keys used by the focused prototype tests.
class CivilpediaSplashAnimationKeys {
  CivilpediaSplashAnimationKeys._();

  static const overlay = ValueKey<String>('civilpedia-splash-overlay');
  static const composition = ValueKey<String>('civilpedia-splash-composition');
  static const wordmark = ValueKey<String>('civilpedia-splash-wordmark');
  static const tagline = ValueKey<String>('civilpedia-splash-tagline');
  static const accent = ValueKey<String>('civilpedia-splash-accent');
  static const signatureShine = ValueKey<String>(
    'civilpedia-splash-signature-shine',
  );

  static ValueKey<String> panel(int index) =>
      ValueKey<String>('civilpedia-splash-panel-$index');
}

/// Reusable, navigation-agnostic Civilpedia opening animation.
///
/// This widget deliberately owns no routing. [destination] is simply revealed
/// after the brand transition, so the same renderer serves the isolated debug
/// preview and the production startup gate. Increment [replaySignal] to replay
/// it in debug tooling.
class CivilpediaSplashAnimation extends StatefulWidget {
  const CivilpediaSplashAnimation({
    required this.destination,
    this.revealReady,
    this.replaySignal = 0,
    this.onCompleted,
    super.key,
  });

  final Widget destination;

  /// Optional production synchronization gate for the final destination fade.
  ///
  /// The approved animation runs unchanged through [SplashMotionSpec.traceFadeEnd].
  /// If this value is still false there, the clean final brand frame is held
  /// until the real startup destination has been resolved and rendered.
  final ValueListenable<bool>? revealReady;
  final int replaySignal;
  final VoidCallback? onCompleted;

  @override
  State<CivilpediaSplashAnimation> createState() =>
      _CivilpediaSplashAnimationState();
}

class _CivilpediaSplashAnimationState extends State<CivilpediaSplashAnimation>
    with SingleTickerProviderStateMixin {
  static const String _standaloneMarkAsset =
      'assets/branding/app_icon_adaptive_foreground.png';
  static const String _officialLockupAsset =
      'assets/branding/splash_logo_display.png';

  late final AnimationController _controller;
  bool _assetsReady = false;
  int _runGeneration = 0;
  int _reportedCompletionGeneration = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashMotionSpec.totalDuration,
    )..addStatusListener(_handleStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsReady) {
      _assetsReady = true;
      _precacheAndStart();
    }
  }

  @override
  void didUpdateWidget(CivilpediaSplashAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replaySignal != oldWidget.replaySignal) {
      _startAnimation();
    }
  }

  Future<void> _precacheAndStart() async {
    await Future.wait([
      precacheImage(const AssetImage(_standaloneMarkAsset), context),
      precacheImage(const AssetImage(_officialLockupAsset), context),
    ]);
    if (!mounted) return;
    _startAnimation();
  }

  void _startAnimation() {
    final generation = ++_runGeneration;
    _controller.stop();

    final revealReady = widget.revealReady;
    if (revealReady == null || revealReady.value) {
      _controller.forward(from: 0);
      return;
    }

    _runWithRevealGate(generation, revealReady);
  }

  Future<void> _runWithRevealGate(
    int generation,
    ValueListenable<bool> revealReady,
  ) async {
    final holdValue =
        SplashMotionSpec.splashFadeStart / SplashMotionSpec.totalMilliseconds;

    try {
      await _controller
          .animateTo(
            holdValue,
            duration: const Duration(
              milliseconds: SplashMotionSpec.splashFadeStart,
            ),
          )
          .orCancel;
      if (!mounted || generation != _runGeneration) return;

      if (!revealReady.value) {
        final ready = Completer<void>();
        void handleReady() {
          if (revealReady.value && !ready.isCompleted) ready.complete();
        }

        revealReady.addListener(handleReady);
        handleReady();
        await ready.future;
        revealReady.removeListener(handleReady);
      }
      if (!mounted || generation != _runGeneration) return;

      await _controller
          .animateTo(
            1,
            duration: const Duration(
              milliseconds:
                  SplashMotionSpec.splashFadeEnd -
                  SplashMotionSpec.splashFadeStart,
            ),
          )
          .orCancel;
      if (!mounted || generation != _runGeneration) return;
      _reportCompletion(generation);
    } on TickerCanceled {
      // Disposal or an explicit debug replay cancels the superseded run.
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _controller.value >= 0.999999) {
      _reportCompletion(_runGeneration);
    }
  }

  void _reportCompletion(int generation) {
    if (_reportedCompletionGeneration == generation) return;
    _reportedCompletionGeneration = generation;
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.destination,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final elapsed =
                  _controller.value * SplashMotionSpec.totalMilliseconds;
              return _SplashOverlay(
                key: CivilpediaSplashAnimationKeys.overlay,
                elapsedMilliseconds: elapsed,
                markAsset: _standaloneMarkAsset,
                lockupAsset: _officialLockupAsset,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  const _SplashOverlay({
    required this.elapsedMilliseconds,
    required this.markAsset,
    required this.lockupAsset,
    super.key,
  });

  final double elapsedMilliseconds;
  final String markAsset;
  final String lockupAsset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final mediaPadding = MediaQuery.paddingOf(context);
        final usableHeight = math.max(1.0, size.height - mediaPadding.vertical);
        final widthFromHeight =
            usableHeight * 0.72 * _BrandGeometry.aspectRatio;
        final compositionWidth = math.min(
          math.min(size.width * 0.90, widthFromHeight),
          390.0,
        );
        final compositionHeight = compositionWidth / _BrandGeometry.aspectRatio;
        final compositionLeft = (size.width - compositionWidth) / 2;
        final compositionTop =
            mediaPadding.top + (usableHeight - compositionHeight) / 2;
        final fadeProgress = _timelineValue(
          elapsedMilliseconds,
          SplashMotionSpec.splashFadeStart,
          SplashMotionSpec.splashFadeEnd,
          Curves.easeOutCubic,
        );
        final splashOpacity = 1 - fadeProgress;
        final showSplashContent = splashOpacity > 0;
        final compositionScale = compositionWidth / _BrandGeometry.designWidth;
        Offset accentPointOnScreen(Offset sourcePoint) {
          final designPoint = _BrandGeometry.markSourcePointInDesign(
            sourcePoint,
          );
          return Offset(
            compositionLeft + designPoint.dx * compositionScale,
            compositionTop + designPoint.dy * compositionScale,
          );
        }

        final horizontalShimmerProgress = _timelineValue(
          elapsedMilliseconds,
          SplashMotionSpec.horizontalShimmerStart,
          SplashMotionSpec.horizontalShimmerEnd,
          Curves.easeInOutCubic,
        );
        final verticalShimmerProgress = _timelineValue(
          elapsedMilliseconds,
          SplashMotionSpec.verticalShimmerStart,
          SplashMotionSpec.verticalShimmerEnd,
          Curves.easeInOutCubic,
        );
        final endpointGlintProgress = _timelineValue(
          elapsedMilliseconds,
          SplashMotionSpec.endpointGlintStart,
          SplashMotionSpec.endpointGlintEnd,
          Curves.easeInOutCubic,
        );
        final traceFadeProgress = _timelineValue(
          elapsedMilliseconds,
          SplashMotionSpec.traceFadeStart,
          SplashMotionSpec.traceFadeEnd,
          Curves.easeOutCubic,
        );
        final cornerBoost =
            (1 -
                    (elapsedMilliseconds -
                                SplashMotionSpec.verticalShimmerStart)
                            .abs() /
                        18)
                .clamp(0.0, 1.0);
        final showShimmer =
            elapsedMilliseconds > SplashMotionSpec.horizontalShimmerStart &&
            elapsedMilliseconds < SplashMotionSpec.traceFadeEnd;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (showSplashContent) ...[
              ColoredBox(
                color: AppColors.surfaceWhite.withValues(alpha: splashOpacity),
              ),
              Positioned(
                key: CivilpediaSplashAnimationKeys.composition,
                left: compositionLeft,
                top: compositionTop,
                width: compositionWidth,
                height: compositionHeight,
                child: RepaintBoundary(
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: _BrandGeometry.designWidth,
                      height: _BrandGeometry.designHeight,
                      child: _BrandComposition(
                        elapsedMilliseconds: elapsedMilliseconds,
                        layerOpacity: splashOpacity,
                        markAsset: markAsset,
                        lockupAsset: lockupAsset,
                      ),
                    ),
                  ),
                ),
              ),
              if (showShimmer)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: CivilpediaSplashAnimationKeys.signatureShine,
                      painter: _LShimmerPainter(
                        topLeft: accentPointOnScreen(
                          _BrandGeometry.yellowAccentVisibleVertices[0],
                        ),
                        topRight: accentPointOnScreen(
                          _BrandGeometry.yellowAccentVisibleVertices[1],
                        ),
                        bottomRight: accentPointOnScreen(
                          _BrandGeometry.yellowAccentVisibleVertices[2],
                        ),
                        horizontalProgress: horizontalShimmerProgress,
                        verticalProgress: verticalShimmerProgress,
                        endpointGlintProgress: endpointGlintProgress,
                        traceOpacity: 1 - traceFadeProgress,
                        layerOpacity: splashOpacity,
                        cornerBoost: cornerBoost,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _BrandComposition extends StatelessWidget {
  const _BrandComposition({
    required this.elapsedMilliseconds,
    required this.layerOpacity,
    required this.markAsset,
    required this.lockupAsset,
  });

  final double elapsedMilliseconds;
  final double layerOpacity;
  final String markAsset;
  final String lockupAsset;

  @override
  Widget build(BuildContext context) {
    final settleProgress = _timelineValue(
      elapsedMilliseconds,
      SplashMotionSpec.settleStart,
      SplashMotionSpec.settleEnd,
      Curves.easeInOutCubic,
    );
    final settleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 0.99), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.99, end: 1.012), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.012, end: 1), weight: 40),
    ]).transform(settleProgress);

    final accentProgress = _timelineValue(
      elapsedMilliseconds,
      SplashMotionSpec.accentStart,
      SplashMotionSpec.accentEnd,
      Curves.easeOutCubic,
    );
    final accentScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.14), weight: 58),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1), weight: 42),
    ]).transform(accentProgress);
    final wordmarkProgress = _timelineValue(
      elapsedMilliseconds,
      SplashMotionSpec.wordmarkStart,
      SplashMotionSpec.wordmarkEnd,
      Curves.easeOutCubic,
    );
    final taglineProgress = _timelineValue(
      elapsedMilliseconds,
      SplashMotionSpec.taglineStart,
      SplashMotionSpec.taglineEnd,
      Curves.easeOutCubic,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: _BrandGeometry.markAssetRect,
          child: Transform.scale(
            scale: settleScale,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (
                  var index = 0;
                  index < _BrandGeometry.bluePanels.length;
                  index++
                )
                  _AnimatedLogoPanel(
                    key: CivilpediaSplashAnimationKeys.panel(index),
                    elapsedMilliseconds: elapsedMilliseconds,
                    asset: markAsset,
                    spec: _BrandGeometry.bluePanels[index],
                    startMilliseconds:
                        SplashMotionSpec.panelStartMilliseconds[index],
                    endMilliseconds:
                        SplashMotionSpec.panelEndMilliseconds[index],
                    layerOpacity: layerOpacity,
                  ),
              ],
            ),
          ),
        ),
        Positioned.fromRect(
          rect: _BrandGeometry.markAssetRect,
          child: _AnimatedAccent(
            key: CivilpediaSplashAnimationKeys.accent,
            asset: markAsset,
            opacity: accentProgress * layerOpacity,
            scale: accentScale,
            baseGlowDim:
                (elapsedMilliseconds >
                        SplashMotionSpec.horizontalShimmerStart &&
                    elapsedMilliseconds < SplashMotionSpec.splashFadeEnd)
                ? 1.0
                : 0.0,
          ),
        ),
        _AnimatedLockupSlice(
          key: CivilpediaSplashAnimationKeys.wordmark,
          asset: lockupAsset,
          sourceRect: _BrandGeometry.wordmarkRect,
          opacity: wordmarkProgress * layerOpacity,
          initialDy: 8,
        ),
        _AnimatedLockupSlice(
          key: CivilpediaSplashAnimationKeys.tagline,
          asset: lockupAsset,
          sourceRect: _BrandGeometry.taglineRect,
          opacity: taglineProgress * layerOpacity,
          initialDy: 5,
        ),
      ],
    );
  }
}

class _AnimatedLogoPanel extends StatelessWidget {
  const _AnimatedLogoPanel({
    required this.elapsedMilliseconds,
    required this.asset,
    required this.spec,
    required this.startMilliseconds,
    required this.endMilliseconds,
    required this.layerOpacity,
    super.key,
  });

  final double elapsedMilliseconds;
  final String asset;
  final _PanelSpec spec;
  final int startMilliseconds;
  final int endMilliseconds;
  final double layerOpacity;

  @override
  Widget build(BuildContext context) {
    final progress = _timelineValue(
      elapsedMilliseconds,
      startMilliseconds,
      endMilliseconds,
      Curves.easeOutCubic,
    );
    final inverse = 1 - progress;

    return Transform.translate(
      offset: spec.initialOffset * inverse,
      child: Transform.rotate(
        angle: spec.initialRotationRadians * inverse,
        alignment: spec.transformAlignment,
        child: Transform.scale(
          scale: 0.94 + (0.06 * progress),
          alignment: spec.transformAlignment,
          child: RepaintBoundary(
            child: ClipPath(
              clipper: _SourcePolygonClipper(spec.sourcePolygon),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                color: AppColors.surfaceWhite.withValues(
                  alpha: progress * layerOpacity,
                ),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedAccent extends StatelessWidget {
  const _AnimatedAccent({
    required this.asset,
    required this.opacity,
    required this.scale,
    required this.baseGlowDim,
    super.key,
  });

  final String asset;
  final double opacity;
  final double scale;
  final double baseGlowDim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: _BrandGeometry.accentGlowRect,
          child: Transform.scale(
            scale: 0.82 + (0.18 * opacity),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _BrandGeometry.brandYellow.withValues(
                      alpha: opacity * 0.24 * (1 - baseGlowDim),
                    ),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        Transform.scale(
          scale: scale,
          alignment: _BrandGeometry.accentAlignment,
          child: RepaintBoundary(
            child: ClipPath(
              clipper: const _SourcePolygonClipper(
                _BrandGeometry.yellowAccentPolygon,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                color: AppColors.surfaceWhite.withValues(alpha: opacity),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LShimmerPainter extends CustomPainter {
  const _LShimmerPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.horizontalProgress,
    required this.verticalProgress,
    required this.endpointGlintProgress,
    required this.traceOpacity,
    required this.layerOpacity,
    required this.cornerBoost,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final double horizontalProgress;
  final double verticalProgress;
  final double endpointGlintProgress;
  final double traceOpacity;
  final double layerOpacity;
  final double cornerBoost;

  // These are final logical screen pixels. This painter sits above the fitted
  // brand composition, so none of these dimensions are asset-scaled again.
  static const double _coreWidth = 3;
  static const double _goldWidth = 5.5;
  static const double _haloWidth = 10;
  static const double _haloBlur = 2.5;
  static const double _tailLength = 32;

  static const double _traceCoreWidth = 2;
  static const double _traceGoldWidth = 4;
  static const double _traceCoreAlpha = 0.62;
  static const double _traceGoldAlpha = 0.46;
  static const double _topDuringVerticalCoreAlpha = 0.58;
  static const double _topDuringVerticalGoldAlpha = 0.42;

  static const double _headCenterRadius = 3.75;
  static const double _headInnerRadius = 5.5;
  static const double _headOuterRadius = 9;
  static const double _headHaloBlur = 2.5;

  static const double _endpointCenterRadius = 3.5;
  static const double _endpointInnerRadius = 5.5;
  static const double _endpointOuterRadius = 8.5;
  static const double _endpointHaloBlur = 2;

  // Fade in over the first ~30 ms of the 220 ms horizontal phase.
  static const double _introFadeProgress = 30 / 220;

  static const Color _coreColor = Color(0xFFFFFFFF);
  static const Color _traceCoreColor = Color(0xFFFFF4D6);
  static const Color _innerWarmColor = Color(0xFFFFF0B8);
  static const Color _goldColor = Color(0xFFFFD15A);

  @override
  void paint(Canvas canvas, Size size) {
    final introOpacity = horizontalProgress > 0 && verticalProgress == 0
        ? (horizontalProgress / _introFadeProgress).clamp(0.0, 1.0)
        : 1.0;
    final drawOpacity = traceOpacity * layerOpacity * introOpacity;

    // Phase A: horizontal edge, left → right.
    if (horizontalProgress > 0 && verticalProgress == 0) {
      final headH = Offset.lerp(topLeft, topRight, horizontalProgress)!;
      final topPath = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(headH.dx, headH.dy);
      _drawTrace(
        canvas,
        topPath,
        coreAlpha: _traceCoreAlpha,
        goldAlpha: _traceGoldAlpha,
        opacity: drawOpacity,
      );
      _drawHorizontalTail(canvas, headH, opacity: drawOpacity);
      _drawHead(canvas, headH, opacity: drawOpacity);
    }

    // Phase B: keep the full top edge illuminated and draw the right edge
    // progressively from the corner down to the moving head.
    if (verticalProgress > 0 && endpointGlintProgress == 0) {
      final headV = Offset.lerp(topRight, bottomRight, verticalProgress)!;
      final topPathFull = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topRight.dx, topRight.dy);
      final rightPath = Path()
        ..moveTo(topRight.dx, topRight.dy)
        ..lineTo(headV.dx, headV.dy);

      _drawTrace(
        canvas,
        topPathFull,
        coreAlpha: _topDuringVerticalCoreAlpha,
        goldAlpha: _topDuringVerticalGoldAlpha,
        opacity: drawOpacity,
      );
      _drawTrace(
        canvas,
        rightPath,
        coreAlpha: _traceCoreAlpha,
        goldAlpha: _traceGoldAlpha,
        opacity: drawOpacity,
      );
      _drawVerticalTail(canvas, headV, opacity: drawOpacity);
      _drawHead(canvas, headV, opacity: drawOpacity);
    }

    // During the endpoint and calm-hold phases, retain the completed L trace.
    if (endpointGlintProgress > 0) {
      final completedPath = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topRight.dx, topRight.dy)
        ..lineTo(bottomRight.dx, bottomRight.dy);
      _drawTrace(
        canvas,
        completedPath,
        coreAlpha: _topDuringVerticalCoreAlpha,
        goldAlpha: _topDuringVerticalGoldAlpha,
        opacity: traceOpacity * layerOpacity,
      );
      if (endpointGlintProgress < 1) {
        _drawEndpointGlint(
          canvas,
          bottomRight,
          endpointGlintProgress,
          layerOpacity,
        );
      }
    }
  }

  void _drawTrace(
    Canvas canvas,
    Path path, {
    required double coreAlpha,
    required double goldAlpha,
    required double opacity,
  }) {
    final goldPaint = Paint()
      ..color = _goldColor.withValues(alpha: goldAlpha * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _traceGoldWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final corePaint = Paint()
      ..color = _traceCoreColor.withValues(alpha: coreAlpha * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _traceCoreWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, goldPaint);
    canvas.drawPath(path, corePaint);
  }

  void _drawHorizontalTail(
    Canvas canvas,
    Offset head, {
    required double opacity,
  }) {
    final tailStart = Offset(
      math.max(topLeft.dx, head.dx - _tailLength),
      head.dy,
    );
    _drawTail(canvas, tailStart, head, opacity: opacity);
  }

  void _drawVerticalTail(
    Canvas canvas,
    Offset head, {
    required double opacity,
  }) {
    final tailStart = Offset(
      head.dx,
      math.max(topRight.dy, head.dy - _tailLength),
    );
    _drawTail(canvas, tailStart, head, opacity: opacity);
  }

  void _drawTail(
    Canvas canvas,
    Offset start,
    Offset end, {
    required double opacity,
  }) {
    if ((end - start).distance < 0.5) return;

    Paint tailPaint({
      required Color color,
      required double alpha,
      required double width,
      double? blur,
    }) {
      return Paint()
        ..shader = ui.Gradient.linear(start, end, [
          color.withValues(alpha: 0),
          color.withValues(alpha: alpha * opacity),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..maskFilter = blur == null
            ? null
            : MaskFilter.blur(BlurStyle.normal, blur);
    }

    canvas
      ..drawLine(
        start,
        end,
        tailPaint(
          color: _BrandGeometry.brandYellow,
          alpha: 0.22,
          width: _haloWidth,
          blur: _haloBlur,
        ),
      )
      ..drawLine(
        start,
        end,
        tailPaint(color: _goldColor, alpha: 0.82, width: _goldWidth),
      )
      ..drawLine(
        start,
        end,
        tailPaint(color: _coreColor, alpha: 1, width: _coreWidth),
      );
  }

  void _drawHead(Canvas canvas, Offset center, {required double opacity}) {
    final boost = 1 + 0.1 * cornerBoost;
    final haloPaint = Paint()
      ..color = _GoldColors.outer.withValues(alpha: 0.25 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _headHaloBlur)
      ..isAntiAlias = true;
    final innerPaint = Paint()
      ..color = _innerWarmColor.withValues(alpha: 0.85 * opacity)
      ..isAntiAlias = true;
    final centerPaint = Paint()
      ..color = _coreColor.withValues(alpha: opacity)
      ..isAntiAlias = true;

    canvas
      ..drawCircle(center, _headOuterRadius * boost, haloPaint)
      ..drawCircle(center, _headInnerRadius * boost, innerPaint)
      ..drawCircle(center, _headCenterRadius * boost, centerPaint);
  }

  void _drawEndpointGlint(
    Canvas canvas,
    Offset center,
    double progress,
    double opacity,
  ) {
    final envelope = math.sin(math.pi * progress);
    if (envelope <= 0) return;

    final haloPaint = Paint()
      ..color = _GoldColors.outer.withValues(alpha: 0.25 * envelope * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _endpointHaloBlur)
      ..isAntiAlias = true;
    final innerPaint = Paint()
      ..color = _innerWarmColor.withValues(alpha: 0.85 * envelope * opacity)
      ..isAntiAlias = true;
    final centerPaint = Paint()
      ..color = _coreColor.withValues(alpha: envelope * opacity)
      ..isAntiAlias = true;

    canvas
      ..drawCircle(center, _endpointOuterRadius * envelope, haloPaint)
      ..drawCircle(center, _endpointInnerRadius * envelope, innerPaint)
      ..drawCircle(center, _endpointCenterRadius * envelope, centerPaint);
  }

  @override
  bool shouldRepaint(_LShimmerPainter oldDelegate) =>
      oldDelegate.topLeft != topLeft ||
      oldDelegate.topRight != topRight ||
      oldDelegate.bottomRight != bottomRight ||
      oldDelegate.horizontalProgress != horizontalProgress ||
      oldDelegate.verticalProgress != verticalProgress ||
      oldDelegate.endpointGlintProgress != endpointGlintProgress ||
      oldDelegate.traceOpacity != traceOpacity ||
      oldDelegate.layerOpacity != layerOpacity ||
      oldDelegate.cornerBoost != cornerBoost;
}

class _GoldColors {
  _GoldColors._();

  static const Color outer = Color(0xFFFFC85A);
}

class _AnimatedLockupSlice extends StatelessWidget {
  const _AnimatedLockupSlice({
    required this.asset,
    required this.sourceRect,
    required this.opacity,
    required this.initialDy,
    super.key,
  });

  final String asset;
  final Rect sourceRect;
  final double opacity;
  final double initialDy;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, initialDy * (1 - opacity)),
      child: RepaintBoundary(
        child: ClipPath(
          clipper: _SourceRectClipper(sourceRect),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            asset,
            width: _BrandGeometry.designWidth,
            height: _BrandGeometry.designHeight,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            color: AppColors.surfaceWhite.withValues(alpha: opacity),
            colorBlendMode: BlendMode.modulate,
          ),
        ),
      ),
    );
  }
}

class _SourcePolygonClipper extends CustomClipper<Path> {
  const _SourcePolygonClipper(this.sourcePoints);

  final List<Offset> sourcePoints;

  @override
  Path getClip(Size size) {
    final path = Path();
    for (var index = 0; index < sourcePoints.length; index++) {
      final sourcePoint = sourcePoints[index];
      final point = Offset(
        sourcePoint.dx / _BrandGeometry.markSourceSize * size.width,
        sourcePoint.dy / _BrandGeometry.markSourceSize * size.height,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldReclip(_SourcePolygonClipper oldClipper) => false;
}

class _SourceRectClipper extends CustomClipper<Path> {
  const _SourceRectClipper(this.sourceRect);

  final Rect sourceRect;

  @override
  Path getClip(Size size) {
    final scaleX = size.width / _BrandGeometry.designWidth;
    final scaleY = size.height / _BrandGeometry.designHeight;
    return Path()..addRect(
      Rect.fromLTRB(
        sourceRect.left * scaleX,
        sourceRect.top * scaleY,
        sourceRect.right * scaleX,
        sourceRect.bottom * scaleY,
      ),
    );
  }

  @override
  bool shouldReclip(_SourceRectClipper oldClipper) => false;
}

class _PanelSpec {
  const _PanelSpec({
    required this.sourcePolygon,
    required this.initialOffset,
    required this.initialRotationDegrees,
    required this.transformCenter,
  });

  final List<Offset> sourcePolygon;
  final Offset initialOffset;
  final double initialRotationDegrees;
  final Offset transformCenter;

  double get initialRotationRadians => initialRotationDegrees * math.pi / 180;

  Alignment get transformAlignment => Alignment(
    (transformCenter.dx / _BrandGeometry.markSourceSize * 2) - 1,
    (transformCenter.dy / _BrandGeometry.markSourceSize * 2) - 1,
  );
}

class _BrandGeometry {
  _BrandGeometry._();

  static const double designWidth = 891;
  static const double designHeight = 836;
  static const double aspectRatio = designWidth / designHeight;
  static const double markSourceSize = 1254;

  // The transparent 1254px standalone source is placed in the official
  // lockup's 891x836 design space without non-uniform scaling.
  static const Rect markAssetRect = Rect.fromLTWH(62, -61, 779, 779);

  static const Rect wordmarkRect = Rect.fromLTRB(32, 635, 859, 741);
  static const Rect taglineRect = Rect.fromLTRB(35, 756, 859, 803);

  static const Color brandYellow = Color(0xFFFE9E03);
  static const Color signatureYellow = Color(0xFFFFC85A);

  // Exact visible yellow bounds in the standalone source are
  // x=892..1032, y=862..1005. The mask is expanded slightly into transparent
  // pixels so clip anti-aliasing cannot introduce a seam.
  static const List<Offset> yellowAccentPolygon = [
    Offset(880, 850),
    Offset(1045, 850),
    Offset(1045, 1020),
  ];

  static const List<Offset> yellowAccentVisibleVertices = [
    Offset(892, 862),
    Offset(1032, 862),
    Offset(1032, 1005),
  ];

  static Offset markSourcePointInDesign(Offset sourcePoint) => Offset(
    markAssetRect.left + sourcePoint.dx / markSourceSize * markAssetRect.width,
    markAssetRect.top + sourcePoint.dy / markSourceSize * markAssetRect.height,
  );

  static const Alignment accentAlignment = Alignment(
    0.534290271132376,
    0.488835725677831,
  );

  static const Rect accentGlowRect = Rect.fromLTWH(
    545.106060606061,
    527.401515151515,
    105,
    105,
  );

  // Panel points are tied to the official 1254px source. The few transparent
  // pixels of overlap around seams prevent raster gaps while keeping each
  // visible surface independent in motion.
  static const List<_PanelSpec> bluePanels = [
    _PanelSpec(
      sourcePolygon: [
        Offset(230, 430),
        Offset(535, 145),
        Offset(880, 145),
        Offset(400, 580),
      ],
      initialOffset: Offset(-120, -105),
      initialRotationDegrees: -4,
      transformCenter: Offset(555, 350),
    ),
    _PanelSpec(
      sourcePolygon: [Offset(850, 145), Offset(1070, 385), Offset(610, 385)],
      initialOffset: Offset(135, -80),
      initialRotationDegrees: 4,
      transformCenter: Offset(850, 300),
    ),
    _PanelSpec(
      sourcePolygon: [
        Offset(230, 405),
        Offset(430, 555),
        Offset(430, 975),
        Offset(230, 840),
      ],
      initialOffset: Offset(-150, 10),
      initialRotationDegrees: -3,
      transformCenter: Offset(330, 690),
    ),
    _PanelSpec(
      sourcePolygon: [
        Offset(405, 660),
        Offset(665, 870),
        Offset(870, 1055),
        Offset(500, 1055),
        Offset(405, 975),
      ],
      initialOffset: Offset(-105, 125),
      initialRotationDegrees: 3,
      transformCenter: Offset(600, 875),
    ),
    _PanelSpec(
      sourcePolygon: [
        Offset(635, 850),
        Offset(878, 856),
        Offset(1060, 1050),
        Offset(843, 1055),
      ],
      initialOffset: Offset(130, 105),
      initialRotationDegrees: -4,
      transformCenter: Offset(875, 955),
    ),
  ];
}

double _timelineValue(
  double elapsedMilliseconds,
  int startMilliseconds,
  int endMilliseconds,
  Curve curve,
) {
  if (elapsedMilliseconds <= startMilliseconds) return 0;
  if (elapsedMilliseconds >= endMilliseconds) return 1;
  final normalized =
      (elapsedMilliseconds - startMilliseconds) /
      (endMilliseconds - startMilliseconds);
  return curve.transform(normalized.clamp(0.0, 1.0));
}
