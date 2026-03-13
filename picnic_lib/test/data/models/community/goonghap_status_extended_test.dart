import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';

void main() {
  group('GoonghapStatus enum', () {
    test('has 4 values', () {
      expect(GoonghapStatus.values.length, 4);
    });

    test('contains all expected values', () {
      expect(GoonghapStatus.values, contains(GoonghapStatus.pending));
      expect(GoonghapStatus.values, contains(GoonghapStatus.completed));
      expect(GoonghapStatus.values, contains(GoonghapStatus.error));
      expect(GoonghapStatus.values, contains(GoonghapStatus.input));
    });
  });

  group('GoonghapStatusX extension', () {
    test('toJson returns correct names', () {
      expect(GoonghapStatus.pending.toJson(), 'pending');
      expect(GoonghapStatus.completed.toJson(), 'completed');
      expect(GoonghapStatus.error.toJson(), 'error');
      expect(GoonghapStatus.input.toJson(), 'input');
    });

    test('fromJson parses pending', () {
      expect(GoonghapStatusX.fromJson('pending'), GoonghapStatus.pending);
    });

    test('fromJson parses completed', () {
      expect(GoonghapStatusX.fromJson('completed'), GoonghapStatus.completed);
    });

    test('fromJson parses error', () {
      expect(GoonghapStatusX.fromJson('error'), GoonghapStatus.error);
    });

    test('fromJson is case-insensitive', () {
      expect(GoonghapStatusX.fromJson('PENDING'), GoonghapStatus.pending);
      expect(GoonghapStatusX.fromJson('Completed'), GoonghapStatus.completed);
      expect(GoonghapStatusX.fromJson('ERROR'), GoonghapStatus.error);
    });

    test('fromJson throws on unknown status', () {
      expect(
        () => GoonghapStatusX.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws on empty string', () {
      expect(
        () => GoonghapStatusX.fromJson(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('LocalizedGoonghap fromJson', () {
    test('parses minimal json', () {
      final lg = LocalizedGoonghap.fromJson({
        'language': 'ko',
      });
      expect(lg.language, 'ko');
      expect(lg.score, 0);
      expect(lg.scoreTitle, '');
      expect(lg.goonghapSummary, '');
    });

    test('parses full json', () {
      final lg = LocalizedGoonghap.fromJson({
        'language': 'en',
        'score': 88,
        'score_title': 'Great Match',
        'goonghap_summary': 'You are compatible!',
        'tips': ['Be yourself', 'Have fun'],
      });
      expect(lg.language, 'en');
      expect(lg.score, 88);
      expect(lg.scoreTitle, 'Great Match');
      expect(lg.goonghapSummary, 'You are compatible!');
      expect(lg.tips.length, 2);
    });
  });

  group('StyleDetails fromJson', () {
    test('parses correctly', () {
      final style = StyleDetails.fromJson({
        'idol_style': 'charismatic',
        'user_style': 'gentle',
        'couple_style': 'balanced',
      });
      expect(style.idolStyle, 'charismatic');
      expect(style.userStyle, 'gentle');
      expect(style.coupleStyle, 'balanced');
    });
  });

  group('ActivitiesDetails fromJson', () {
    test('parses correctly', () {
      final activities = ActivitiesDetails.fromJson({
        'recommended': ['cafe', 'movie', 'park'],
        'description': 'Fun activities together',
      });
      expect(activities.recommended.length, 3);
      expect(activities.description, 'Fun activities together');
    });
  });

  group('Details fromJson', () {
    test('parses full details', () {
      final details = Details.fromJson({
        'style': {
          'idol_style': 'cool',
          'user_style': 'warm',
          'couple_style': 'perfect',
        },
        'activities': {
          'recommended': ['travel'],
          'description': 'Great together',
        },
      });
      expect(details.style.idolStyle, 'cool');
      expect(details.activities.recommended.first, 'travel');
    });
  });
}
