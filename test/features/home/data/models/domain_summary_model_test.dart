import 'package:finlife_superapp/features/home/data/models/domain_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainSummaryModel.fromJson', () {
    test('allows a missing status_line and falls back to an empty string', () {
      final model = DomainSummaryModel.fromJson({
        'domain': 'consumer',
        'title': 'Shopping',
        'headline_value': '2 orders in transit',
        'is_stale': false,
      });

      expect(model.domainKey, 'consumer');
      expect(model.title, 'Shopping');
      expect(model.headlineValue, '2 orders in transit');
      expect(model.statusLine, isEmpty);
      expect(model.isStale, isFalse);
    });
  });
}
