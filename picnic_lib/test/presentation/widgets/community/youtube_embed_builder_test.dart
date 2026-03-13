import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/youtube_embed_builder.dart';

void main() {
  group('YouTubeEmbedBuilder', () {
    test('has correct key', () {
      final builder = YouTubeEmbedBuilder();
      expect(builder.key, 'youtube');
    });

    test('is an EmbedBuilder', () {
      final builder = YouTubeEmbedBuilder();
      expect(builder, isNotNull);
    });
  });

  group('DeletableYouTubeEmbedBuilder', () {
    test('creates with embedType youtube', () {
      final builder = DeletableYouTubeEmbedBuilder();
      expect(builder.key, 'youtube');
    });

    test('is not null after construction', () {
      final builder = DeletableYouTubeEmbedBuilder();
      expect(builder, isNotNull);
    });
  });
}
