import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/write/embed_builder/deletable_embed_builder.dart';

void main() {
  group('DeletableEmbedBuilder', () {
    test('has correct key matching embedType', () {
      final builder = DeletableEmbedBuilder(
        embedType: 'custom',
        contentBuilder: (context, node) => const SizedBox(),
      );
      expect(builder.key, 'custom');
    });

    test('embedType is stored correctly', () {
      final builder = DeletableEmbedBuilder(
        embedType: 'youtube',
        contentBuilder: (context, node) => const SizedBox(),
      );
      expect(builder.embedType, 'youtube');
      expect(builder.key, 'youtube');
    });

    test('contentBuilder is stored correctly', () {
      Widget myBuilder(BuildContext context, Embed node) =>
          const Text('test');
      final builder = DeletableEmbedBuilder(
        embedType: 'link',
        contentBuilder: myBuilder,
      );
      expect(builder.contentBuilder, myBuilder);
    });

    test('different embedTypes create different builders', () {
      final builder1 = DeletableEmbedBuilder(
        embedType: 'youtube',
        contentBuilder: (_, __) => const SizedBox(),
      );
      final builder2 = DeletableEmbedBuilder(
        embedType: 'image',
        contentBuilder: (_, __) => const SizedBox(),
      );
      expect(builder1.key, isNot(builder2.key));
    });

    test('empty embedType is allowed', () {
      final builder = DeletableEmbedBuilder(
        embedType: '',
        contentBuilder: (_, __) => const SizedBox(),
      );
      expect(builder.key, '');
      expect(builder.embedType, '');
    });

    test('is an EmbedBuilder', () {
      final builder = DeletableEmbedBuilder(
        embedType: 'test',
        contentBuilder: (_, __) => const SizedBox(),
      );
      expect(builder, isA<EmbedBuilder>());
    });
  });
}
