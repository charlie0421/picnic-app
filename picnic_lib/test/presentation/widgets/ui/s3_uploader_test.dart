import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/s3_uploader.dart';

// Test subclass to access private methods
class TestableS3Uploader extends S3Uploader {
  TestableS3Uploader({
    required super.accessKey,
    required super.secretKey,
    required super.region,
    required super.bucketName,
  });

  // Expose private methods for testing via calling through uploadFile
  // We test indirectly through the error paths and construction
}

void main() {
  late S3Uploader uploader;

  setUp(() {
    uploader = S3Uploader(
      accessKey: 'AKIAIOSFODNN7EXAMPLE',
      secretKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
      region: 'us-east-1',
      bucketName: 'test-bucket',
    );
  });

  group('S3Uploader construction', () {
    test('stores parameters correctly', () {
      expect(uploader.accessKey, 'AKIAIOSFODNN7EXAMPLE');
      expect(uploader.secretKey, 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY');
      expect(uploader.region, 'us-east-1');
      expect(uploader.bucketName, 'test-bucket');
    });

    test('accepts different regions', () {
      final apUploader = S3Uploader(
        accessKey: 'key',
        secretKey: 'secret',
        region: 'ap-northeast-2',
        bucketName: 'kr-bucket',
      );
      expect(apUploader.region, 'ap-northeast-2');
      expect(apUploader.bucketName, 'kr-bucket');
    });

    test('accepts empty strings', () {
      final emptyUploader = S3Uploader(
        accessKey: '',
        secretKey: '',
        region: '',
        bucketName: '',
      );
      expect(emptyUploader.accessKey, '');
      expect(emptyUploader.secretKey, '');
      expect(emptyUploader.region, '');
      expect(emptyUploader.bucketName, '');
    });

    test('accepts special characters in bucket name', () {
      final specialUploader = S3Uploader(
        accessKey: 'key',
        secretKey: 'secret',
        region: 'us-west-2',
        bucketName: 'my-test-bucket.example.com',
      );
      expect(specialUploader.bucketName, 'my-test-bucket.example.com');
    });
  });

  group('S3Uploader uploadFile error handling', () {
    test('빈 자격증명은 파일 처리 전에 업로드를 거부한다', () async {
      final disabledUploader = S3Uploader(
        accessKey: ' ',
        secretKey: '',
        region: 'ap-northeast-2',
        bucketName: 'bucket',
      );

      await expectLater(
        disabledUploader.uploadFile('post/image', Object(), (_) {}),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Community integration is disabled',
          ),
        ),
      );
    });

    test('throws exception for non-File and non-Uint8List input', () async {
      expect(
        () => uploader.uploadFile('folder', 'invalid_file', (p) {}),
        throwsException,
      );
    });

    test('throws exception for null input', () async {
      expect(
        () => uploader.uploadFile('folder', null, (p) {}),
        throwsException,
      );
    });

    test('throws exception for int input', () async {
      expect(
        () => uploader.uploadFile('folder', 42, (p) {}),
        throwsException,
      );
    });

    test('throws exception for list input', () async {
      expect(
        () => uploader.uploadFile('folder', [1, 2, 3], (p) {}),
        throwsException,
      );
    });

    test('throws exception for map input', () async {
      expect(
        () => uploader.uploadFile('folder', {'key': 'value'}, (p) {}),
        throwsException,
      );
    });

    test('throws exception for bool input', () async {
      expect(
        () => uploader.uploadFile('folder', true, (p) {}),
        throwsException,
      );
    });

    test('throws exception for double input', () async {
      expect(
        () => uploader.uploadFile('folder', 3.14, (p) {}),
        throwsException,
      );
    });
  });

  group('S3Uploader with different configurations', () {
    test('multiple instances are independent', () {
      final uploader1 = S3Uploader(
        accessKey: 'key1',
        secretKey: 'secret1',
        region: 'us-east-1',
        bucketName: 'bucket1',
      );
      final uploader2 = S3Uploader(
        accessKey: 'key2',
        secretKey: 'secret2',
        region: 'eu-west-1',
        bucketName: 'bucket2',
      );

      expect(uploader1.accessKey, isNot(uploader2.accessKey));
      expect(uploader1.region, isNot(uploader2.region));
      expect(uploader1.bucketName, isNot(uploader2.bucketName));
    });

    test('all AWS regions accepted', () {
      final regions = [
        'us-east-1', 'us-west-2', 'eu-west-1', 'ap-northeast-2',
        'ap-southeast-1', 'sa-east-1', 'ca-central-1',
      ];
      for (final region in regions) {
        final u = S3Uploader(
          accessKey: 'key',
          secretKey: 'secret',
          region: region,
          bucketName: 'bucket',
        );
        expect(u.region, region);
      }
    });
  });
}
