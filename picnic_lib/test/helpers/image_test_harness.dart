import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/file.dart';
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as image;

final class ImageTestHarness implements BaseCacheManager {
  ImageTestHarness._(this._previousCacheManager)
    : _root = MemoryFileSystem().directory('/image-test-harness')
        ..createSync(recursive: true);

  static Future<ImageTestHarness> create() async {
    if (!_hasSafeDefaultManager) {
      // Assign before reading the lazy static field. Reading the package's
      // real default here initializes path_provider-backed storage in widget
      // tests, where no platform channel is installed.
      CachedNetworkImageProvider.defaultCacheManager = _safeDefaultManager;
      _hasSafeDefaultManager = true;
    }
    final harness = ImageTestHarness._(
      CachedNetworkImageProvider.defaultCacheManager,
    );
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    CachedNetworkImageProvider.defaultCacheManager = harness;
    return harness;
  }

  static final BaseCacheManager _safeDefaultManager =
      _UnusedImageTestCacheManager();
  static bool _hasSafeDefaultManager = false;

  final BaseCacheManager _previousCacheManager;
  final Directory _root;
  final Map<String, _FixtureResponse> _responses = {};
  final Map<String, FileInfo> _cachedFiles = {};
  final Map<String, Future<FileInfo>> _runningRequests = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, ListQueue<Object>> _failures = {};
  final Set<Completer<void>> _openStreams = {};

  int _nextFileId = 0;
  int _activeRequests = 0;
  int _maximumActiveRequests = 0;
  bool _disposed = false;

  Future<void> respondPng(
    String url, {
    int width = 400,
    int height = 200,
    Color color = const Color(0xffff0000),
    bool held = false,
  }) async {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('PNG dimensions must be positive.');
    }
    final argb = color.toARGB32();
    final fixture = image.Image(width: width, height: height, numChannels: 4);
    image.fill(
      fixture,
      color: image.ColorRgba8(
        (argb >> 16) & 0xff,
        (argb >> 8) & 0xff,
        argb & 0xff,
        (argb >> 24) & 0xff,
      ),
    );
    await _registerResponse(
      url,
      Uint8List.fromList(image.encodePng(fixture)),
      extension: 'png',
      held: held,
    );
  }

  Future<void> respondAnimatedGif(String url, {bool held = false}) {
    return _registerResponse(
      url,
      base64Decode(_animatedGifBase64),
      extension: 'gif',
      held: held,
    );
  }

  void failNext(String url, Object error) {
    _failures.putIfAbsent(url, ListQueue<Object>.new).add(error);
  }

  void release(String url) {
    _responses[url]?.release();
  }

  int requestsFor(String url) => _requestCounts[url] ?? 0;

  int get activeRequests => _activeRequests;

  int get maximumActiveRequests => _maximumActiveRequests;

  Future<void> _registerResponse(
    String url,
    Uint8List bytes, {
    required String extension,
    required bool held,
  }) async {
    _checkNotDisposed();
    final file = _root.childFile('${_nextFileId++}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    _responses[url] = _FixtureResponse(file, held: held);
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    _checkNotDisposed();
    final streamDone = Completer<void>();
    _openStreams.add(streamDone);
    try {
      final cacheKey = key ?? url;
      final cached = _cachedFiles[cacheKey];
      if (cached != null && cached.file.existsSync()) {
        yield FileInfo(cached.file, FileSource.Cache, cached.validTill, url);
        return;
      }

      yield await _loadCold(url, cacheKey);
    } finally {
      _openStreams.remove(streamDone);
      if (!streamDone.isCompleted) streamDone.complete();
    }
  }

  Future<FileInfo> _loadCold(String url, String cacheKey) {
    final running = _runningRequests[cacheKey];
    if (running != null) return running;

    final future = _performColdRequest(url, cacheKey);
    _runningRequests[cacheKey] = future;
    future.then<void>(
      (_) {
        if (identical(_runningRequests[cacheKey], future)) {
          _runningRequests.remove(cacheKey);
        }
      },
      onError: (Object _, StackTrace _) {
        if (identical(_runningRequests[cacheKey], future)) {
          _runningRequests.remove(cacheKey);
        }
      },
    );
    return future;
  }

  Future<FileInfo> _performColdRequest(String url, String cacheKey) async {
    _requestCounts.update(url, (count) => count + 1, ifAbsent: () => 1);
    _activeRequests++;
    if (_activeRequests > _maximumActiveRequests) {
      _maximumActiveRequests = _activeRequests;
    }

    try {
      final failures = _failures[url];
      if (failures != null && failures.isNotEmpty) {
        final error = failures.removeFirst();
        Error.throwWithStackTrace(error, StackTrace.current);
      }

      final response = _responses[url];
      if (response == null) {
        throw StateError('No image response registered for $url');
      }
      await response.waitUntilReleased();

      final info = FileInfo(
        response.file,
        FileSource.Online,
        DateTime.utc(2099),
        url,
      );
      _cachedFiles[cacheKey] = info;
      return info;
    } finally {
      _activeRequests--;
    }
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    return (await _loadCachedOrCold(url, key ?? url)).file;
  }

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async* {
    yield await _loadCachedOrCold(url, key ?? url);
  }

  Future<FileInfo> _loadCachedOrCold(String url, String cacheKey) {
    final cached = _cachedFiles[cacheKey];
    if (cached != null && cached.file.existsSync()) {
      return Future.value(
        FileInfo(cached.file, FileSource.Cache, cached.validTill, url),
      );
    }
    return _loadCold(url, cacheKey);
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) {
    final cacheKey = key ?? url;
    if (force) _cachedFiles.remove(cacheKey);
    return _loadCachedOrCold(url, cacheKey);
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    final cached = _cachedFiles[key];
    return cached != null && cached.file.existsSync() ? cached : null;
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) => getFileFromCache(key);

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final file = _root.childFile('${_nextFileId++}.$fileExtension');
    await file.writeAsBytes(fileBytes, flush: true);
    _cachedFiles[key ?? url] = FileInfo(
      file,
      FileSource.Online,
      DateTime.now().add(maxAge),
      url,
    );
    return file;
  }

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in source) {
      bytes.add(chunk);
    }
    return putFile(
      url,
      bytes.takeBytes(),
      key: key,
      eTag: eTag,
      maxAge: maxAge,
      fileExtension: fileExtension,
    );
  }

  @override
  Future<void> removeFile(String key) async {
    _cachedFiles.remove(key);
  }

  @override
  Future<void> emptyCache() async {
    _cachedFiles.clear();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final response in _responses.values) {
      response.release();
    }
    if (_openStreams.isNotEmpty) {
      await Future.wait(_openStreams.map((stream) => stream.future));
    }
    if (identical(CachedNetworkImageProvider.defaultCacheManager, this)) {
      CachedNetworkImageProvider.defaultCacheManager = _previousCacheManager;
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (_root.existsSync()) _root.deleteSync(recursive: true);
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('ImageTestHarness is disposed.');
  }
}

final class _FixtureResponse {
  _FixtureResponse(this.file, {required bool held})
    : _releaseGate = held ? Completer<void>() : null;

  final File file;
  final Completer<void>? _releaseGate;

  Future<void> waitUntilReleased() =>
      _releaseGate?.future ?? Future<void>.value();

  void release() {
    final gate = _releaseGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}

const String _animatedGifBase64 =
    'R0lGODlhBAACAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQICgAAACwA'
    'AAAABAACAAAIBwABCBwoMCAAIfkECAoAAAAsAAAAAAQAAgCBAAD/AAAAAAAAAAAACAcAAQgc'
    'KDAgADs=';

final class _UnusedImageTestCacheManager implements BaseCacheManager {
  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
