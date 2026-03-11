import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/navigation_stack.dart';

void main() {
  group('NavigationStack', () {
    late NavigationStack stack;

    setUp(() {
      stack = NavigationStack();
    });

    test('초기 상태는 비어있음', () {
      expect(stack.isEmpty, isTrue);
      expect(stack.length, equals(0));
    });

    test('initialPage로 생성하면 1개', () {
      final s = NavigationStack(initialPage: const SizedBox());
      expect(s.isEmpty, isFalse);
      expect(s.length, equals(1));
    });

    test('push 후 길이 증가', () {
      stack.push(const SizedBox());
      expect(stack.length, equals(1));
      expect(stack.isEmpty, isFalse);
    });

    test('여러 개 push', () {
      stack.push(const SizedBox());
      stack.push(const Text('hello'));
      stack.push(const Icon(Icons.star));
      expect(stack.length, equals(3));
    });

    test('pop은 마지막 요소 반환', () {
      final first = const SizedBox(key: Key('first'));
      final second = const SizedBox(key: Key('second'));
      stack.push(first);
      stack.push(second);

      final popped = stack.pop();
      expect(popped, same(second));
      expect(stack.length, equals(1));
    });

    test('빈 스택에서 pop하면 StateError', () {
      expect(() => stack.pop(), throwsStateError);
    });

    test('peek은 마지막 요소 반환 (제거하지 않음)', () {
      final widget = const SizedBox(key: Key('test'));
      stack.push(widget);

      expect(stack.peek(), same(widget));
      expect(stack.length, equals(1)); // 여전히 1개
    });

    test('빈 스택에서 peek하면 StateError', () {
      expect(() => stack.peek(), throwsStateError);
    });

    test('clear로 모두 제거', () {
      stack.push(const SizedBox());
      stack.push(const SizedBox());
      stack.push(const SizedBox());
      stack.clear();
      expect(stack.isEmpty, isTrue);
      expect(stack.length, equals(0));
    });

    test('items는 읽기 전용 리스트 반환', () {
      stack.push(const SizedBox());
      stack.push(const Text('hello'));
      final items = stack.items;
      expect(items.length, equals(2));
      // 수정 불가
      expect(() => items.add(const SizedBox()), throwsUnsupportedError);
    });

    test('toString은 문자열 반환', () {
      stack.push(const SizedBox());
      expect(stack.toString(), isA<String>());
    });

    test('push-pop-push 시퀀스', () {
      stack.push(const SizedBox(key: Key('a')));
      stack.push(const SizedBox(key: Key('b')));
      stack.pop();
      stack.push(const SizedBox(key: Key('c')));
      expect(stack.length, equals(2));
      expect(stack.peek().key, equals(const Key('c')));
    });
  });
}
