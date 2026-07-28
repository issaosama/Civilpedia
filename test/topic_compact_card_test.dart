import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_compact_card.dart';

EngineeringTopic _createTopic({
  List<String> keyTopics = const [],
  List<String> tags = const [],
  String coverImageUrl = '',
}) {
  return EngineeringTopic(
    id: 'test',
    titleAr: 'عنوان اختبار',
    categoryId: 'concrete',
    summary: 'هذا ملخص اختبار للموضوع',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    keyTopics: keyTopics,
    tags: tags,
    coverImageUrl: coverImageUrl.isEmpty ? null : coverImageUrl,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  group('TopicCompactCard home variant', () {
    testWidgets('renders the topic title', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      expect(find.text('عنوان اختبار'), findsOneWidget);
    });

    testWidgets('renders the description', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      expect(find.text('هذا ملخص اختبار للموضوع'), findsOneWidget);
    });

    testWidgets('description uses maxLines 1 in home variant', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      final text = tester.widget<Text>(find.text('هذا ملخص اختبار للموضوع'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('respects chip limit of 2 in home variant', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(
            keyTopics: ['خرسانة', 'مقاومة', 'اختبار'],
          ),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      expect(find.text('خرسانة'), findsOneWidget);
      expect(find.text('مقاومة'), findsOneWidget);
      expect(find.text('اختبار'), findsNothing);
    });
  });

  group('TopicCompactCard preview variant', () {
    testWidgets('renders the topic title', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.preview,
          onTap: () {},
        ),
      ));
      expect(find.text('عنوان اختبار'), findsOneWidget);
    });

    testWidgets('description uses maxLines 1 in preview variant', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.preview,
          onTap: () {},
        ),
      ));
      final text = tester.widget<Text>(find.text('هذا ملخص اختبار للموضوع'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('respects chip limit of 1 in preview variant', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(
            keyTopics: ['خرسانة', 'مقاومة'],
          ),
          isDark: false,
          variant: TopicCompactCardVariant.preview,
          onTap: () {},
        ),
      ));
      expect(find.text('خرسانة'), findsOneWidget);
      expect(find.text('مقاومة'), findsNothing);
    });
  });

  group('TopicCompactCard shared behavior', () {
    testWidgets('invokes onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('عنوان اختبار'));
      expect(tapped, isTrue);
    });

    testWidgets('renders safely with empty keyTopics using tags fallback', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(tags: ['وسم']),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      expect(find.text('وسم'), findsOneWidget);
    });

    testWidgets('renders safely when both keyTopics and tags are empty', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      // Should render without chips but still show title/description
      expect(find.text('عنوان اختبار'), findsOneWidget);
      expect(find.text('هذا ملخص اختبار للموضوع'), findsOneWidget);
    });

    testWidgets('cover fallback renders when coverImageUrl is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      // Category header fallback contains an icon
      expect(find.byIcon(Icons.view_agenda), findsOneWidget);
    });

    testWidgets('renders with cover image url without throwing', (tester) async {
      await tester.pumpWidget(_wrap(
        TopicCompactCard(
          topic: _createTopic(coverImageUrl: 'nonexistent.png'),
          isDark: false,
          variant: TopicCompactCardVariant.home,
          onTap: () {},
        ),
      ));
      // Image.asset with missing asset in test mode shows error widget;
      // verifying it does not crash
      expect(find.text('عنوان اختبار'), findsOneWidget);
    });
  });
}
