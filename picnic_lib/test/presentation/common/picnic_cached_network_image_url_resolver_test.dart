import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image_url_resolver.dart';

void main() {
  const resolver = PicnicCachedNetworkImageUrlResolver(
    cdnUrl: 'https://test-cdn.example.com',
  );
  const standardVariant = [
    PicnicCachedNetworkImageUrlVariant(resolutionMultiplier: 1.5, quality: 85),
  ];

  group('PicnicCachedNetworkImageUrlResolver', () {
    test('CDN absolute URL의 기존 query를 w/h/q로 변환한다', () {
      expect(
        resolver.resolve(
          imageUrl: 'https://test-cdn.example.com/artist/1.jpg?fit=cover&old=1',
          width: 100,
          height: 80,
          variants: standardVariant,
        ),
        ['https://test-cdn.example.com/artist/1.jpg?q=85&w=150&h=120'],
      );
    });

    test('CDN relative path를 base URL에 결합하고 w/h/q를 붙인다', () {
      expect(
        resolver.resolve(
          imageUrl: '/artist/1.jpg',
          width: 100,
          height: 80,
          variants: standardVariant,
        ),
        ['https://test-cdn.example.com/artist/1.jpg?q=85&w=150&h=120'],
      );
    });

    test('외부 signed URL은 query와 문자열 표기를 그대로 보존한다', () {
      const signedUrl =
          'HTTPS://images.example.com/photo.jpg?X-Amz-Signature=abc%2F123&expires=9';

      expect(
        resolver.resolve(
          imageUrl: '  $signedUrl  ',
          width: 100,
          height: 80,
          variants: standardVariant,
        ),
        [signedUrl],
      );
    });

    group('CDN origin 판정', () {
      test('scheme이 다르면 변환하지 않는다', () {
        const url = 'http://test-cdn.example.com/image.jpg?sig=abc';
        expect(
          resolver.resolve(
            imageUrl: url,
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          [url],
        );
      });

      test('host가 다르면 변환하지 않는다', () {
        const url = 'https://other.example.com/image.jpg?sig=abc';
        expect(
          resolver.resolve(
            imageUrl: url,
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          [url],
        );
      });

      test('port가 다르면 변환하지 않는다', () {
        const url = 'https://test-cdn.example.com:8443/image.jpg?sig=abc';
        expect(
          resolver.resolve(
            imageUrl: url,
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          [url],
        );
      });

      test('기본 port를 명시한 같은 origin은 변환한다', () {
        expect(
          resolver.resolve(
            imageUrl: 'https://test-cdn.example.com:443/image.jpg',
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          ['https://test-cdn.example.com/image.jpg?q=85&w=150&h=120'],
        );
      });

      test('trailing dot이 붙은 같은 CDN host는 변환한다', () {
        expect(
          resolver.resolve(
            imageUrl: 'https://test-cdn.example.com./image.jpg',
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          ['https://test-cdn.example.com./image.jpg?q=85&w=150&h=120'],
        );
      });
    });

    group('protocol-relative URL', () {
      test('CDN host는 https로 승격한 뒤 변환한다', () {
        expect(
          resolver.resolve(
            imageUrl: '//test-cdn.example.com/image.jpg',
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          ['https://test-cdn.example.com/image.jpg?q=85&w=150&h=120'],
        );
      });

      test('외부 host는 https로 승격만 하고 query를 보존한다', () {
        expect(
          resolver.resolve(
            imageUrl: '//images.example.com/image.jpg?token=signed',
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          ['https://images.example.com/image.jpg?token=signed'],
        );
      });
    });

    group('non-network와 blank 입력', () {
      test('http/https가 아닌 scheme은 기존처럼 CDN relative path로 처리한다', () {
        expect(
          resolver.resolve(
            imageUrl: 'asset://images/local.png',
            width: 100,
            height: 80,
            variants: standardVariant,
          ),
          [
            'https://test-cdn.example.com/asset://images/local.png?q=85&w=150&h=120',
          ],
        );
      });

      test('빈 문자열과 공백은 CDN root relative path로 처리한다', () {
        for (final imageUrl in ['', '   ']) {
          expect(
            resolver.resolve(
              imageUrl: imageUrl,
              width: 100,
              height: 80,
              variants: standardVariant,
            ),
            ['https://test-cdn.example.com/?q=85&w=150&h=120'],
          );
        }
      });
    });

    test('CDN query를 교체하되 fragment는 보존한다', () {
      expect(
        resolver.resolve(
          imageUrl:
              'https://test-cdn.example.com/image.jpg?token=old&fit=cover#hero',
          width: 50,
          height: 25,
          variants: const [
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 1,
              quality: 70,
            ),
          ],
        ),
        ['https://test-cdn.example.com/image.jpg?q=70&w=50&h=25#hero'],
      );
    });

    group('dimensions', () {
      test('null 또는 non-finite dimension은 query에서 생략한다', () {
        expect(
          resolver.resolve(
            imageUrl: 'image.jpg',
            width: double.infinity,
            height: double.nan,
            variants: standardVariant,
          ),
          ['https://test-cdn.example.com/image.jpg?q=85'],
        );
      });

      test('계산된 dimension은 반올림하고 최소 1로 제한한다', () {
        expect(
          resolver.resolve(
            imageUrl: 'image.jpg',
            width: 0.1,
            height: 0,
            variants: const [
              PicnicCachedNetworkImageUrlVariant(
                resolutionMultiplier: 0.1,
                quality: 85,
              ),
            ],
          ),
          ['https://test-cdn.example.com/image.jpg?q=85&w=1&h=1'],
        );
      });
    });

    test('CDN progressive variant를 전달된 순서대로 해석한다', () {
      expect(
        resolver.resolve(
          imageUrl: 'image.jpg',
          width: 101,
          height: 99,
          variants: const [
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 0.3,
              quality: 25,
            ),
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 0.6,
              quality: 50,
            ),
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 1,
              quality: 80,
            ),
          ],
        ),
        [
          'https://test-cdn.example.com/image.jpg?q=25&w=30&h=30',
          'https://test-cdn.example.com/image.jpg?q=50&w=61&h=59',
          'https://test-cdn.example.com/image.jpg?q=80&w=101&h=99',
        ],
      );
    });

    test('외부 URL은 variant 수와 무관하게 단일 원본 URL만 반환한다', () {
      const externalUrl = 'https://images.example.com/image.jpg?token=signed';
      expect(
        resolver.resolve(
          imageUrl: externalUrl,
          width: 300,
          height: 300,
          variants: const [
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 0.3,
              quality: 25,
            ),
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 0.6,
              quality: 50,
            ),
            PicnicCachedNetworkImageUrlVariant(
              resolutionMultiplier: 1,
              quality: 80,
            ),
          ],
        ),
        [externalUrl],
      );
    });
  });
}
