import 'package:flutter_test/flutter_test.dart';
import 'package:civilpedia/features/encyclopedia/domain/entities/engineering_topic.dart';
import 'package:civilpedia/features/encyclopedia/presentation/widgets/topic_card_chip.dart';

void main() {
  group('topicCardLabels', () {
    EngineeringTopic createTopic({
      List<String> keyTopics = const [],
      List<String> tags = const [],
    }) {
      return EngineeringTopic(
        id: 'test',
        titleAr: 'Test',
        categoryId: 'concrete',
        summary: 'Test summary',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        keyTopics: keyTopics,
        tags: tags,
      );
    }

    test('prefers keyTopics when available', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['الخرسانة', 'المقاومة'], tags: ['tag1']),
      );
      expect(result, ['الخرسانة', 'المقاومة']);
    });

    test('falls back to tags when keyTopics is empty', () {
      final result = topicCardLabels(
        createTopic(tags: ['tag1', 'tag2']),
      );
      expect(result, ['tag1', 'tag2']);
    });

    test('trims whitespace from labels', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['  خرسانة  ', '  مقاومة  ']),
      );
      expect(result, ['خرسانة', 'مقاومة']);
    });

    test('removes empty labels after trimming', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['خرسانة', '', '   ', 'مقاومة']),
      );
      expect(result, ['خرسانة', 'مقاومة']);
    });

    test('removes duplicate labels while preserving order', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['خرسانة', 'مقاومة', 'خرسانة', ' اختبار']),
        maxChips: 3,
      );
      expect(result, ['خرسانة', 'مقاومة', 'اختبار']);
    });

    test('respects maxChips limit', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['خرسانة', 'مقاومة', 'اختبار', 'جودة']),
        maxChips: 2,
      );
      expect(result.length, 2);
      expect(result, ['خرسانة', 'مقاومة']);
    });

    test('returns at most maxChips even with many labels', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['a', 'b', 'c', 'd', 'e']),
        maxChips: 3,
      );
      expect(result.length, 3);
    });

    test('returns empty list when both sources are empty', () {
      final result = topicCardLabels(createTopic());
      expect(result, isEmpty);
    });

    test('returns empty list when all labels are whitespace', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['   ', '', ' ']),
      );
      expect(result, isEmpty);
    });

    test('returns empty list when maxChips is 0', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['خرسانة', 'مقاومة']),
        maxChips: 0,
      );
      expect(result, isEmpty);
    });

    test('works correctly with a single keyTopic', () {
      final result = topicCardLabels(
        createTopic(keyTopics: ['خرسانة']),
      );
      expect(result, ['خرسانة']);
    });

    test('works correctly with a single tag', () {
      final result = topicCardLabels(
        createTopic(tags: ['tag1']),
      );
      expect(result, ['tag1']);
    });
  });
}
