// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/boards_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BoardDetail)
const boardDetailProvider = BoardDetailFamily._();

final class BoardDetailProvider
    extends $AsyncNotifierProvider<BoardDetail, BoardModel?> {
  const BoardDetailProvider._({
    required BoardDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'boardDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boardDetailHash();

  @override
  String toString() {
    return r'boardDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BoardDetail create() => BoardDetail();

  @override
  bool operator ==(Object other) {
    return other is BoardDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boardDetailHash() => r'78f2428dcb66cdb181f2b01d6a774b13ec20c3e1';

final class BoardDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          BoardDetail,
          AsyncValue<BoardModel?>,
          BoardModel?,
          FutureOr<BoardModel?>,
          String
        > {
  const BoardDetailFamily._()
    : super(
        retry: null,
        name: r'boardDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BoardDetailProvider call(String boardId) =>
      BoardDetailProvider._(argument: boardId, from: this);

  @override
  String toString() => r'boardDetailProvider';
}

abstract class _$BoardDetail extends $AsyncNotifier<BoardModel?> {
  late final _$args = ref.$arg as String;
  String get boardId => _$args;

  FutureOr<BoardModel?> build(String boardId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<BoardModel?>, BoardModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BoardModel?>, BoardModel?>,
              AsyncValue<BoardModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(BoardsNotifier)
const boardsProvider = BoardsNotifierFamily._();

final class BoardsNotifierProvider
    extends $AsyncNotifierProvider<BoardsNotifier, List<BoardModel>?> {
  const BoardsNotifierProvider._({
    required BoardsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'boardsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boardsNotifierHash();

  @override
  String toString() {
    return r'boardsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BoardsNotifier create() => BoardsNotifier();

  @override
  bool operator ==(Object other) {
    return other is BoardsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boardsNotifierHash() => r'6094360199f46222ef825611c73d73b377726a3f';

final class BoardsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BoardsNotifier,
          AsyncValue<List<BoardModel>?>,
          List<BoardModel>?,
          FutureOr<List<BoardModel>?>,
          int
        > {
  const BoardsNotifierFamily._()
    : super(
        retry: null,
        name: r'boardsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BoardsNotifierProvider call(int artistId) =>
      BoardsNotifierProvider._(argument: artistId, from: this);

  @override
  String toString() => r'boardsProvider';
}

abstract class _$BoardsNotifier extends $AsyncNotifier<List<BoardModel>?> {
  late final _$args = ref.$arg as int;
  int get artistId => _$args;

  FutureOr<List<BoardModel>?> build(int artistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<BoardModel>?>, List<BoardModel>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BoardModel>?>, List<BoardModel>?>,
              AsyncValue<List<BoardModel>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(BoardsByArtistNameNotifier)
const boardsByArtistNameProvider = BoardsByArtistNameNotifierFamily._();

final class BoardsByArtistNameNotifierProvider
    extends
        $AsyncNotifierProvider<BoardsByArtistNameNotifier, List<BoardModel>?> {
  const BoardsByArtistNameNotifierProvider._({
    required BoardsByArtistNameNotifierFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'boardsByArtistNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$boardsByArtistNameNotifierHash();

  @override
  String toString() {
    return r'boardsByArtistNameProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BoardsByArtistNameNotifier create() => BoardsByArtistNameNotifier();

  @override
  bool operator ==(Object other) {
    return other is BoardsByArtistNameNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$boardsByArtistNameNotifierHash() =>
    r'4725ecd95a76c3ab2cfabaac8b4d83848cfe65a4';

final class BoardsByArtistNameNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BoardsByArtistNameNotifier,
          AsyncValue<List<BoardModel>?>,
          List<BoardModel>?,
          FutureOr<List<BoardModel>?>,
          (String, int, int)
        > {
  const BoardsByArtistNameNotifierFamily._()
    : super(
        retry: null,
        name: r'boardsByArtistNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BoardsByArtistNameNotifierProvider call(String query, int page, int limit) =>
      BoardsByArtistNameNotifierProvider._(
        argument: (query, page, limit),
        from: this,
      );

  @override
  String toString() => r'boardsByArtistNameProvider';
}

abstract class _$BoardsByArtistNameNotifier
    extends $AsyncNotifier<List<BoardModel>?> {
  late final _$args = ref.$arg as (String, int, int);
  String get query => _$args.$1;
  int get page => _$args.$2;
  int get limit => _$args.$3;

  FutureOr<List<BoardModel>?> build(String query, int page, int limit);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args.$1, _$args.$2, _$args.$3);
    final ref =
        this.ref as $Ref<AsyncValue<List<BoardModel>?>, List<BoardModel>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BoardModel>?>, List<BoardModel>?>,
              AsyncValue<List<BoardModel>?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(BoardRequestNotifier)
const boardRequestProvider = BoardRequestNotifierProvider._();

final class BoardRequestNotifierProvider
    extends $AsyncNotifierProvider<BoardRequestNotifier, BoardModel?> {
  const BoardRequestNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boardRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boardRequestNotifierHash();

  @$internal
  @override
  BoardRequestNotifier create() => BoardRequestNotifier();
}

String _$boardRequestNotifierHash() =>
    r'59a8a35fc10e649ba487756b7727f2ea95c58fdd';

abstract class _$BoardRequestNotifier extends $AsyncNotifier<BoardModel?> {
  FutureOr<BoardModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<BoardModel?>, BoardModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BoardModel?>, BoardModel?>,
              AsyncValue<BoardModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
