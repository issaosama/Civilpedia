import 'package:civilpedia/features/splash/presentation/civilpedia_splash_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion timeline includes the approved full-lockup hold', () {
    expect(SplashMotionSpec.totalDuration, const Duration(milliseconds: 2890));
    expect(SplashMotionSpec.backgroundOnlyEnd, 120);
    expect(SplashMotionSpec.panelStartMilliseconds, [120, 185, 250, 315, 380]);
    expect(SplashMotionSpec.panelEndMilliseconds.last, 900);
    expect(SplashMotionSpec.taglineEnd, 1650);
    expect(
      SplashMotionSpec.horizontalShimmerStart - SplashMotionSpec.taglineEnd,
      350,
    );
    expect(
      SplashMotionSpec.horizontalShimmerEnd -
          SplashMotionSpec.horizontalShimmerStart,
      220,
    );
    expect(
      SplashMotionSpec.verticalShimmerEnd -
          SplashMotionSpec.verticalShimmerStart,
      220,
    );
    expect(
      SplashMotionSpec.endpointGlintEnd - SplashMotionSpec.endpointGlintStart,
      110,
    );
    expect(SplashMotionSpec.splashFadeStart, 2670);
    expect(
      SplashMotionSpec.splashFadeEnd - SplashMotionSpec.splashFadeStart,
      220,
    );
  });

  testWidgets('builds five independent panels and reveals the destination', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CivilpediaSplashAnimation(
          destination: const ColoredBox(
            key: ValueKey<String>('preview-destination'),
            color: Colors.white,
          ),
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    for (var index = 0; index < 5; index++) {
      expect(
        find.byKey(CivilpediaSplashAnimationKeys.panel(index)),
        findsOneWidget,
      );
    }
    expect(find.byKey(CivilpediaSplashAnimationKeys.wordmark), findsOneWidget);
    expect(find.byKey(CivilpediaSplashAnimationKeys.tagline), findsOneWidget);
    expect(find.byKey(CivilpediaSplashAnimationKeys.accent), findsOneWidget);

    await tester.pump(
      const Duration(
        milliseconds: SplashMotionSpec.horizontalShimmerStart + 70,
      ),
    );
    expect(
      find.byKey(CivilpediaSplashAnimationKeys.signatureShine),
      findsOneWidget,
    );
    expect(
      find.byKey(CivilpediaSplashAnimationKeys.composition),
      findsOneWidget,
    );

    await tester.pump(
      const Duration(
        milliseconds:
            SplashMotionSpec.totalMilliseconds -
            SplashMotionSpec.horizontalShimmerStart -
            70 +
            100,
      ),
    );
    await tester.pump();

    expect(completed, isTrue);
    expect(find.byKey(const ValueKey('preview-destination')), findsOneWidget);
    expect(find.byKey(CivilpediaSplashAnimationKeys.composition), findsNothing);
    expect(
      find.byKey(CivilpediaSplashAnimationKeys.signatureShine),
      findsNothing,
    );
  });

  testWidgets('a changed replay signal restarts the overlay', (tester) async {
    var replaySignal = 0;
    var completionCount = 0;
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, stateSetter) {
            setState = stateSetter;
            return CivilpediaSplashAnimation(
              replaySignal: replaySignal,
              onCompleted: () => completionCount++,
              destination: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump(
      SplashMotionSpec.totalDuration + const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(completionCount, 1);

    setState(() => replaySignal++);
    await tester.pump();

    expect(
      find.byKey(CivilpediaSplashAnimationKeys.composition),
      findsOneWidget,
    );

    await tester.pump(
      SplashMotionSpec.totalDuration + const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(completionCount, 2);
  });

  testWidgets('holds the clean final brand frame until destination is ready', (
    tester,
  ) async {
    final revealReady = ValueNotifier<bool>(false);
    var completed = false;
    addTearDown(revealReady.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CivilpediaSplashAnimation(
          revealReady: revealReady,
          destination: const ColoredBox(
            key: ValueKey<String>('resolved-destination'),
            color: Colors.white,
          ),
          onCompleted: () => completed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    await tester.pump(
      const Duration(milliseconds: SplashMotionSpec.splashFadeStart),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(completed, isFalse);
    expect(
      find.byKey(CivilpediaSplashAnimationKeys.composition),
      findsOneWidget,
    );

    revealReady.value = true;
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 20));

    expect(completed, isTrue);
    expect(find.byKey(CivilpediaSplashAnimationKeys.composition), findsNothing);
  });
}
