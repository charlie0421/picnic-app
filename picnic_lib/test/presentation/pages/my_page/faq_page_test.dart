import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';

/// Tests for FAQPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// flutter_quill, Supabase.instance.client).
/// We test all importable production code: FAQPage widget constructor,
/// QnaCategory model, QnaThread model, PatchInfo, UpdateInfo, Setting,
/// and constants.
void main() {
  group('FAQPage widget', () {
    test('can be const-constructed', () {
      const page = FAQPage();
      expect(page, isA<FAQPage>());
    });

    test('with key can be constructed', () {
      const page = FAQPage(key: ValueKey('faq'));
      expect(page.key, equals(const ValueKey('faq')));
    });
  });

  group('QnaCategory model', () {
    test('constructor with required fields', () {
      final category = QnaCategory(code: 'general', label: '일반 문의');
      expect(category.code, 'general');
      expect(category.label, '일반 문의');
      expect(category.questionTemplate, isNull);
      expect(category.answerTemplate, isNull);
    });

    test('constructor with all fields', () {
      final category = QnaCategory(
        code: 'payment',
        label: '결제 문의',
        questionTemplate: '주문번호:',
        answerTemplate: '답변 템플릿',
      );
      expect(category.code, 'payment');
      expect(category.questionTemplate, contains('주문번호'));
      expect(category.answerTemplate, '답변 템플릿');
    });

    test('empty code', () {
      final category = QnaCategory(code: '', label: '선택');
      expect(category.code.isEmpty, isTrue);
    });

    test('code.isNotEmpty for selection state', () {
      final selected = QnaCategory(code: 'account', label: '계정');
      final unselected = QnaCategory(code: '', label: '선택');
      expect(selected.code.isNotEmpty, isTrue);
      expect(unselected.code.isNotEmpty, isFalse);
    });
  });

  group('QnaThread model for list display', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'title': 'FAQ Thread',
        'created_at': '2026-03-01T10:00:00.000',
        'updated_at': '2026-03-01T14:00:00.000',
        'status': 'RECEIVED',
      };
      final thread = QnaThread.fromJson(json);
      expect(thread.id, 1);
      expect(thread.title, 'FAQ Thread');
    });

    test('status extensions', () {
      final received = QnaThread(
        id: 1, userId: 'u', title: 't',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      expect(received.isReceived, isTrue);
      expect(received.isOpen, isTrue);

      final resolved = QnaThread(
        id: 2, userId: 'u', title: 't',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RESOLVED',
      );
      expect(resolved.isResolved, isTrue);
      expect(resolved.isClosed, isTrue);
    });

    test('toJson roundtrip', () {
      final original = QnaThread(
        id: 5, userId: 'u', title: 'Roundtrip',
        createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
        status: 'IN_PROGRESS',
      );
      final json = original.toJson();
      final restored = QnaThread.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.status, original.status);
    });

    test('copyWith', () {
      final thread = QnaThread(
        id: 1, userId: 'u', title: 'Original',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        status: 'RECEIVED',
      );
      final updated = thread.copyWith(title: 'Updated', status: 'RESOLVED');
      expect(updated.title, 'Updated');
      expect(updated.status, 'RESOLVED');
      expect(updated.id, 1);
    });
  });

  group('PatchInfo model', () {
    test('default values', () {
      const info = PatchInfo();
      expect(info.hasUpdate, isFalse);
      expect(info.updateDownloaded, isFalse);
      expect(info.needsRestart, isFalse);
      expect(info.currentPatch, isNull);
      expect(info.newPatch, isNull);
    });

    test('displayInfo for no patch', () {
      const info = PatchInfo();
      expect(info.displayInfo, contains('No patch'));
    });

    test('displayInfo for current patch', () {
      const info = PatchInfo(currentPatch: 3);
      expect(info.displayInfo, contains('3'));
    });

    test('displayInfo for restart', () {
      const info = PatchInfo(needsRestart: true);
      expect(info.displayInfo, contains('restart'));
    });

    test('displayInfo for downloaded', () {
      const info = PatchInfo(updateDownloaded: true);
      expect(info.displayInfo, contains('downloaded'));
    });

    test('displayInfo for available', () {
      const info = PatchInfo(hasUpdate: true);
      expect(info.displayInfo, contains('available'));
    });

    test('canRestart', () {
      expect(const PatchInfo(needsRestart: true).canRestart, isTrue);
      expect(const PatchInfo().canRestart, isFalse);
    });

    test('copyWith', () {
      const info = PatchInfo(currentPatch: 5);
      final updated = info.copyWith(statusMessage: 'test', hasUpdate: true);
      expect(updated.currentPatch, 5);
      expect(updated.statusMessage, 'test');
      expect(updated.hasUpdate, isTrue);
    });
  });

  group('UpdateInfo model', () {
    test('construction and field access', () {
      final info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      expect(info.status, UpdateStatus.upToDate);
      expect(info.currentVersion, '1.0.0');
      expect(info.url, isNull);
    });

    test('copyWith', () {
      final info = UpdateInfo(
        status: UpdateStatus.upToDate,
        currentVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceVersion: '0.9.0',
      );
      final updated = info.copyWith(status: UpdateStatus.needPatch);
      expect(updated.status, UpdateStatus.needPatch);
      expect(updated.currentVersion, '1.0.0');
    });
  });

  group('UpdateStatus enum', () {
    test('has 4 values', () {
      expect(UpdateStatus.values.length, 4);
    });

    test('contains all statuses', () {
      expect(UpdateStatus.values, contains(UpdateStatus.upToDate));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRecommended));
      expect(UpdateStatus.values, contains(UpdateStatus.updateRequired));
      expect(UpdateStatus.values, contains(UpdateStatus.needPatch));
    });
  });

  group('Setting model', () {
    test('default values', () {
      const setting = Setting();
      expect(setting.themeMode, ThemeMode.system);
      expect(setting.language, 'ko');
    });

    test('copyWith', () {
      const setting = Setting();
      final updated = setting.copyWith(language: 'en', themeMode: ThemeMode.dark);
      expect(updated.language, 'en');
      expect(updated.themeMode, ThemeMode.dark);
    });

    test('supportedLanguages', () {
      final languages = Setting.supportedLanguages;
      expect(languages.isNotEmpty, isTrue);
      expect(languages, contains('ko'));
      expect(languages, contains('en'));
    });
  });

  group('parseThemeMode', () {
    test('parses all valid modes', () {
      expect(parseThemeMode('light'), ThemeMode.light);
      expect(parseThemeMode('dark'), ThemeMode.dark);
      expect(parseThemeMode('system'), ThemeMode.system);
    });

    test('unknown defaults to system', () {
      expect(parseThemeMode(''), ThemeMode.system);
    });
  });

  group('languageMap and countryMap from production code', () {
    test('languageMap has 12 entries', () {
      expect(languageMap.length, 12);
    });

    test('countryMap has matching entries', () {
      for (final key in languageMap.keys) {
        expect(countryMap.containsKey(key), isTrue);
      }
    });

    test('parseLocale works for all keys', () {
      for (final code in languageMap.keys) {
        final locale = parseLocale(code);
        expect(locale.languageCode.isNotEmpty, isTrue);
      }
    });
  });

  group('PicnicAuthExceptions from production code', () {
    test('canceled()', () {
      final ex = PicnicAuthExceptions.canceled();
      expect(ex.code, 'canceled');
    });

    test('network()', () {
      final ex = PicnicAuthExceptions.network();
      expect(ex.code, 'network_error');
    });

    test('unknown()', () {
      final ex = PicnicAuthExceptions.unknown();
      expect(ex.code, 'unknown');
    });

    test('deviceBanned()', () {
      final ex = PicnicAuthExceptions.deviceBanned();
      expect(ex.statusCode, 'DEVICE_BANNED');
    });
  });

  group('Constants', () {
    test('Constants.webWidth', () {
      expect(Constants.webWidth, 375);
    });

    test('NavBarConstants.bottomNavHeight', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
    });

    test('webDesignSize', () {
      expect(webDesignSize, const Size(600, 800));
    });
  });
}
