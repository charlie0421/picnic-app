import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/pic/pic_camera_view_page.dart';

/// Tests for enums defined in pic_camera_view_page.dart.
/// The widget itself (PicCameraViewPage) requires the camera plugin and
/// cannot be rendered in widget tests.
void main() {
  group('ViewMode enum', () {
    test('has all expected values', () {
      expect(ViewMode.values, hasLength(4));
      expect(ViewMode.values, contains(ViewMode.loading));
      expect(ViewMode.values, contains(ViewMode.ready));
      expect(ViewMode.values, contains(ViewMode.timer));
      expect(ViewMode.values, contains(ViewMode.saving));
    });

    test('loading has index 0', () {
      expect(ViewMode.loading.index, 0);
    });

    test('ready has index 1', () {
      expect(ViewMode.ready.index, 1);
    });

    test('timer has index 2', () {
      expect(ViewMode.timer.index, 2);
    });

    test('saving has index 3', () {
      expect(ViewMode.saving.index, 3);
    });

    test('each value has unique name', () {
      final names = ViewMode.values.map((v) => v.name).toSet();
      expect(names.length, ViewMode.values.length);
    });

    test('name returns correct strings', () {
      expect(ViewMode.loading.name, 'loading');
      expect(ViewMode.ready.name, 'ready');
      expect(ViewMode.timer.name, 'timer');
      expect(ViewMode.saving.name, 'saving');
    });
  });

  group('ViewType enum', () {
    test('has all expected values', () {
      expect(ViewType.values, hasLength(2));
      expect(ViewType.values, contains(ViewType.camera));
      expect(ViewType.values, contains(ViewType.image));
    });

    test('camera has index 0', () {
      expect(ViewType.camera.index, 0);
    });

    test('image has index 1', () {
      expect(ViewType.image.index, 1);
    });

    test('name returns correct strings', () {
      expect(ViewType.camera.name, 'camera');
      expect(ViewType.image.name, 'image');
    });

    test('each value has unique name', () {
      final names = ViewType.values.map((v) => v.name).toSet();
      expect(names.length, ViewType.values.length);
    });
  });

  group('ViewMode and ViewType are distinct types', () {
    test('ViewMode is not ViewType', () {
      expect(ViewMode.loading, isNot(isA<ViewType>()));
    });

    test('ViewType is not ViewMode', () {
      expect(ViewType.camera, isNot(isA<ViewMode>()));
    });
  });
}
