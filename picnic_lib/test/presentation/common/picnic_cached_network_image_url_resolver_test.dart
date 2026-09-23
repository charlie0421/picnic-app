import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image_url_resolver.dart';

void main() {
  const resolver = PicnicCachedNetworkImageUrlResolver(
    cdnUrl: 'https://test-cdn.example.com',
  );

  String fixedWidth(String imageUrl, {int width = 150, int quality = 85}) {
    return resolver.resolveFixedWidth(imageUrl, width: width, quality: quality);
  }

  group('resolveFixedWidth', () {
    test('CDN absolute URL의 기존 query를 q/w로 교체한다', () {
      expect(
        fixedWidth('https://test-cdn.example.com/artist/1.jpg?fit=cover&old=1'),
        'https://test-cdn.example.com/artist/1.jpg?q=85&w=150',
      );
    });

    test('CDN relative path를 base URL에 결합하고 q/w를 붙인다', () {
      expect(
        fixedWidth('/artist/1.jpg'),
        'https://test-cdn.example.com/artist/1.jpg?q=85&w=150',
      );
    });

    test('높이는 보내지 않는다 (CDN 이 비율을 유지한다)', () {
      final query = Uri.parse(fixedWidth('artist/1.jpg')).queryParameters;

      expect(query.keys, ['q', 'w']);
    });

    test('외부 signed URL은 query와 문자열 표기를 그대로 보존한다', () {
      const signedUrl =
          'HTTPS://images.example.com/photo.jpg?X-Amz-Signature=abc%2F123&expires=9';

      expect(fixedWidth('  $signedUrl  '), signedUrl);
    });

    group('CDN origin 판정', () {
      // 레거시 행은 같은 CDN host 를 http 로 적어 둔다. 기본 포트면 같은 CDN
      // 이므로 설정된 https origin 으로 옮겨 고정 변형을 받는다 — 그대로 두면
      // 원본이 평문 http 로 내려간다.
      test('기본 포트 http 의 같은 CDN host 는 https origin 으로 정규화한다', () {
        expect(
          fixedWidth('http://test-cdn.example.com/image.jpg?sig=abc#hero'),
          'https://test-cdn.example.com/image.jpg?q=85&w=150#hero',
        );
      });

      test('명시한 :80 과 대문자 표기도 같은 https origin 으로 정규화한다', () {
        for (final url in [
          'http://test-cdn.example.com:80/image.jpg',
          'HTTP://TEST-CDN.example.com./image.jpg',
        ]) {
          expect(
            fixedWidth(url),
            'https://test-cdn.example.com/image.jpg?q=85&w=150',
            reason: url,
          );
        }
      });

      test('http 라도 기본 포트가 아니거나 계정 정보가 있으면 변환하지 않는다', () {
        for (final url in [
          'http://test-cdn.example.com:8080/image.jpg?sig=abc',
          'http://user:secret@test-cdn.example.com/image.jpg?sig=abc',
        ]) {
          expect(fixedWidth(url), url);
        }
      });

      test('같은 CDN host라도 계정 정보가 있는 https URL은 보존한다', () {
        const url =
            'https://user:secret@test-cdn.example.com/image.jpg?sig=abc';
        expect(fixedWidth(url), url);
      });

      test('계정 정보가 있는 protocol-relative URL은 HTTPS로만 승격한다', () {
        const url = '//user:secret@test-cdn.example.com/image.jpg?sig=abc';
        expect(
          fixedWidth(url),
          'https://user:secret@test-cdn.example.com/image.jpg?sig=abc',
        );
      });

      test('다른 host 의 http 서명 URL 은 그대로 둔다', () {
        const url = 'http://images.example.com/image.jpg?X-Amz-Signature=a%2Bb';
        expect(fixedWidth(url), url);
      });

      test('host가 다르면 변환하지 않는다', () {
        const url = 'https://other.example.com/image.jpg?sig=abc';
        expect(fixedWidth(url), url);
      });

      test('port가 다르면 변환하지 않는다', () {
        const url = 'https://test-cdn.example.com:8443/image.jpg?sig=abc';
        expect(fixedWidth(url), url);
      });

      test('설정된 CDN이 커스텀 포트면 기본 포트 http를 별개 origin으로 둔다', () {
        const customPortResolver = PicnicCachedNetworkImageUrlResolver(
          cdnUrl: 'https://test-cdn.example.com:8443',
        );
        const url = 'http://test-cdn.example.com/image.jpg?sig=abc';

        expect(
          customPortResolver.resolveFixedWidth(url, width: 150, quality: 85),
          url,
        );
      });

      test('기본 port를 명시한 같은 origin은 변환한다', () {
        expect(
          fixedWidth('https://test-cdn.example.com:443/image.jpg'),
          'https://test-cdn.example.com/image.jpg?q=85&w=150',
        );
      });

      test('trailing dot이 붙은 같은 CDN host는 변환한다', () {
        expect(
          fixedWidth('https://test-cdn.example.com./image.jpg'),
          'https://test-cdn.example.com./image.jpg?q=85&w=150',
        );
      });
    });

    group('protocol-relative URL', () {
      test('CDN host는 https로 승격한 뒤 변환한다', () {
        expect(
          fixedWidth('//test-cdn.example.com/image.jpg'),
          'https://test-cdn.example.com/image.jpg?q=85&w=150',
        );
      });

      test('외부 host는 https로 승격만 하고 query를 보존한다', () {
        expect(
          fixedWidth('//images.example.com/image.jpg?token=signed'),
          'https://images.example.com/image.jpg?token=signed',
        );
      });
    });

    group('non-network와 blank 입력', () {
      test('http/https가 아닌 scheme은 기존처럼 CDN relative path로 처리한다', () {
        expect(
          fixedWidth('asset://images/local.png'),
          'https://test-cdn.example.com/asset://images/local.png?q=85&w=150',
        );
      });

      test('빈 문자열과 공백은 CDN root relative path로 처리한다', () {
        for (final imageUrl in ['', '   ']) {
          expect(
            fixedWidth(imageUrl),
            'https://test-cdn.example.com/?q=85&w=150',
          );
        }
      });
    });

    test('CDN query를 교체하되 fragment는 보존한다', () {
      expect(
        fixedWidth(
          'https://test-cdn.example.com/image.jpg?token=old&fit=cover#hero',
          width: 50,
          quality: 70,
        ),
        'https://test-cdn.example.com/image.jpg?q=70&w=50#hero',
      );
    });

    test('0 이하 폭과 1~100 밖 품질은 명시적으로 거부한다', () {
      expect(() => fixedWidth('image.jpg', width: 0), throwsRangeError);
      expect(() => fixedWidth('image.jpg', quality: 0), throwsRangeError);
      expect(() => fixedWidth('image.jpg', quality: 101), throwsRangeError);
    });

    test('relative path는 CDN URL 없이 해석하지 않는다', () {
      const withoutCdn = PicnicCachedNetworkImageUrlResolver(cdnUrl: null);

      expect(
        () => withoutCdn.resolveFixedWidth('image.jpg', width: 1, quality: 1),
        throwsStateError,
      );
    });
  });
}
