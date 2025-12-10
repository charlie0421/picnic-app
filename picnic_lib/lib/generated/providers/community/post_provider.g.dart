// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/post_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postsByArtist)
const postsByArtistProvider = PostsByArtistFamily._();

final class PostsByArtistProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostModel>?>,
          List<PostModel>?,
          FutureOr<List<PostModel>?>
        >
    with $FutureModifier<List<PostModel>?>, $FutureProvider<List<PostModel>?> {
  const PostsByArtistProvider._({
    required PostsByArtistFamily super.from,
    required (int, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'postsByArtistProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postsByArtistHash();

  @override
  String toString() {
    return r'postsByArtistProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PostModel>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostModel>?> create(Ref ref) {
    final argument = this.argument as (int, int, int);
    return postsByArtist(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByArtistProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postsByArtistHash() => r'6f4ea1afa9585e1d4dd941ae5b26d28233fc139f';

final class PostsByArtistFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<PostModel>?>, (int, int, int)> {
  const PostsByArtistFamily._()
    : super(
        retry: null,
        name: r'postsByArtistProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostsByArtistProvider call(int artistId, int limit, int page) =>
      PostsByArtistProvider._(argument: (artistId, limit, page), from: this);

  @override
  String toString() => r'postsByArtistProvider';
}

@ProviderFor(postsByBoard)
const postsByBoardProvider = PostsByBoardFamily._();

final class PostsByBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostModel>?>,
          List<PostModel>?,
          FutureOr<List<PostModel>?>
        >
    with $FutureModifier<List<PostModel>?>, $FutureProvider<List<PostModel>?> {
  const PostsByBoardProvider._({
    required PostsByBoardFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'postsByBoardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postsByBoardHash();

  @override
  String toString() {
    return r'postsByBoardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PostModel>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostModel>?> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return postsByBoard(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByBoardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postsByBoardHash() => r'85a71afdb2023b30ffeb684d8b9df33cbc57fbf3';

final class PostsByBoardFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PostModel>?>,
          (String, int, int)
        > {
  const PostsByBoardFamily._()
    : super(
        retry: null,
        name: r'postsByBoardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostsByBoardProvider call(String boardId, int limit, int page) =>
      PostsByBoardProvider._(argument: (boardId, limit, page), from: this);

  @override
  String toString() => r'postsByBoardProvider';
}

@ProviderFor(postsByQuery)
const postsByQueryProvider = PostsByQueryFamily._();

final class PostsByQueryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostModel>?>,
          List<PostModel>?,
          FutureOr<List<PostModel>?>
        >
    with $FutureModifier<List<PostModel>?>, $FutureProvider<List<PostModel>?> {
  const PostsByQueryProvider._({
    required PostsByQueryFamily super.from,
    required (int, String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'postsByQueryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postsByQueryHash();

  @override
  String toString() {
    return r'postsByQueryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PostModel>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostModel>?> create(Ref ref) {
    final argument = this.argument as (int, String, int, int);
    return postsByQuery(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByQueryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postsByQueryHash() => r'ef605c58d2b8add4caa8150f3fd1cde86144a952';

final class PostsByQueryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PostModel>?>,
          (int, String, int, int)
        > {
  const PostsByQueryFamily._()
    : super(
        retry: null,
        name: r'postsByQueryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostsByQueryProvider call(int artistId, String query, int page, int limit) =>
      PostsByQueryProvider._(
        argument: (artistId, query, page, limit),
        from: this,
      );

  @override
  String toString() => r'postsByQueryProvider';
}

@ProviderFor(postById)
const postByIdProvider = PostByIdFamily._();

final class PostByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<PostModel?>,
          PostModel?,
          FutureOr<PostModel?>
        >
    with $FutureModifier<PostModel?>, $FutureProvider<PostModel?> {
  const PostByIdProvider._({
    required PostByIdFamily super.from,
    required (String, {bool isIncrementViewCount}) super.argument,
  }) : super(
         retry: null,
         name: r'postByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postByIdHash();

  @override
  String toString() {
    return r'postByIdProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<PostModel?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PostModel?> create(Ref ref) {
    final argument = this.argument as (String, {bool isIncrementViewCount});
    return postById(
      ref,
      argument.$1,
      isIncrementViewCount: argument.isIncrementViewCount,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postByIdHash() => r'0467e8687c5e1edaae8df28bc3051c02644ee771';

final class PostByIdFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<PostModel?>,
          (String, {bool isIncrementViewCount})
        > {
  const PostByIdFamily._()
    : super(
        retry: null,
        name: r'postByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostByIdProvider call(String postId, {bool isIncrementViewCount = true}) =>
      PostByIdProvider._(
        argument: (postId, isIncrementViewCount: isIncrementViewCount),
        from: this,
      );

  @override
  String toString() => r'postByIdProvider';
}

@ProviderFor(postsByUser)
const postsByUserProvider = PostsByUserFamily._();

final class PostsByUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostModel>>,
          List<PostModel>,
          FutureOr<List<PostModel>>
        >
    with $FutureModifier<List<PostModel>>, $FutureProvider<List<PostModel>> {
  const PostsByUserProvider._({
    required PostsByUserFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'postsByUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postsByUserHash();

  @override
  String toString() {
    return r'postsByUserProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PostModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostModel>> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return postsByUser(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsByUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postsByUserHash() => r'f47bffd3c1249a02f9d990b83add6cfc27e74286';

final class PostsByUserFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PostModel>>,
          (String, int, int)
        > {
  const PostsByUserFamily._()
    : super(
        retry: null,
        name: r'postsByUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostsByUserProvider call(String userId, int limit, int page) =>
      PostsByUserProvider._(argument: (userId, limit, page), from: this);

  @override
  String toString() => r'postsByUserProvider';
}

@ProviderFor(postsScrapedByUser)
const postsScrapedByUserProvider = PostsScrapedByUserFamily._();

final class PostsScrapedByUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PostScrapModel>>,
          List<PostScrapModel>,
          FutureOr<List<PostScrapModel>>
        >
    with
        $FutureModifier<List<PostScrapModel>>,
        $FutureProvider<List<PostScrapModel>> {
  const PostsScrapedByUserProvider._({
    required PostsScrapedByUserFamily super.from,
    required (String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'postsScrapedByUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postsScrapedByUserHash();

  @override
  String toString() {
    return r'postsScrapedByUserProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PostScrapModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PostScrapModel>> create(Ref ref) {
    final argument = this.argument as (String, int, int);
    return postsScrapedByUser(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is PostsScrapedByUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postsScrapedByUserHash() =>
    r'6eb871d1c0860ccb52bf1f910bc921f75c25708f';

final class PostsScrapedByUserFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PostScrapModel>>,
          (String, int, int)
        > {
  const PostsScrapedByUserFamily._()
    : super(
        retry: null,
        name: r'postsScrapedByUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostsScrapedByUserProvider call(String userId, int limit, int page) =>
      PostsScrapedByUserProvider._(argument: (userId, limit, page), from: this);

  @override
  String toString() => r'postsScrapedByUserProvider';
}

@ProviderFor(reportPost)
const reportPostProvider = ReportPostFamily._();

final class ReportPostProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const ReportPostProvider._({
    required ReportPostFamily super.from,
    required (PostModel, String, String, {bool blockUser}) super.argument,
  }) : super(
         retry: null,
         name: r'reportPostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportPostHash();

  @override
  String toString() {
    return r'reportPostProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument =
        this.argument as (PostModel, String, String, {bool blockUser});
    return reportPost(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      blockUser: argument.blockUser,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReportPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportPostHash() => r'0a8f3188a618917e44fa2edc45dbb7aa9f347699';

final class ReportPostFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          (PostModel, String, String, {bool blockUser})
        > {
  const ReportPostFamily._()
    : super(
        retry: null,
        name: r'reportPostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReportPostProvider call(
    PostModel post,
    String reason,
    String text, {
    bool blockUser = false,
  }) => ReportPostProvider._(
    argument: (post, reason, text, blockUser: blockUser),
    from: this,
  );

  @override
  String toString() => r'reportPostProvider';
}

@ProviderFor(deletePost)
const deletePostProvider = DeletePostFamily._();

final class DeletePostProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const DeletePostProvider._({
    required DeletePostFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deletePostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deletePostHash();

  @override
  String toString() {
    return r'deletePostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return deletePost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeletePostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deletePostHash() => r'14edd1b452c2311c8e788e36bcd75d3fd51a91b7';

final class DeletePostFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  const DeletePostFamily._()
    : super(
        retry: null,
        name: r'deletePostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DeletePostProvider call(String postId) =>
      DeletePostProvider._(argument: postId, from: this);

  @override
  String toString() => r'deletePostProvider';
}

@ProviderFor(scrapPost)
const scrapPostProvider = ScrapPostFamily._();

final class ScrapPostProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const ScrapPostProvider._({
    required ScrapPostFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scrapPostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scrapPostHash();

  @override
  String toString() {
    return r'scrapPostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return scrapPost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScrapPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scrapPostHash() => r'92ea67c79075d4dac5997c6706a61137a1a95af5';

final class ScrapPostFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  const ScrapPostFamily._()
    : super(
        retry: null,
        name: r'scrapPostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ScrapPostProvider call(String postId) =>
      ScrapPostProvider._(argument: postId, from: this);

  @override
  String toString() => r'scrapPostProvider';
}

@ProviderFor(unscrapPost)
const unscrapPostProvider = UnscrapPostFamily._();

final class UnscrapPostProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  const UnscrapPostProvider._({
    required UnscrapPostFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'unscrapPostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$unscrapPostHash();

  @override
  String toString() {
    return r'unscrapPostProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, String);
    return unscrapPost(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is UnscrapPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unscrapPostHash() => r'4030912f54313496bad8d6ac19dad85033205c62';

final class UnscrapPostFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, String)> {
  const UnscrapPostFamily._()
    : super(
        retry: null,
        name: r'unscrapPostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UnscrapPostProvider call(String postId, String userId) =>
      UnscrapPostProvider._(argument: (postId, userId), from: this);

  @override
  String toString() => r'unscrapPostProvider';
}
