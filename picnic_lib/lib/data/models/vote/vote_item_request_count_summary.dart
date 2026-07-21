import 'dart:collection';

class VoteItemRequestCountSummary {
  VoteItemRequestCountSummary._({
    required this.totalCount,
    required Map<int, int> countsByArtistId,
    required Map<String, int> countsByArtistName,
    required Map<int, String> artistNamesById,
    required Map<int, Map<String, int>> statusCountsByArtistId,
  }) : countsByArtistId = UnmodifiableMapView(countsByArtistId),
       countsByArtistName = UnmodifiableMapView(countsByArtistName),
       artistNamesById = UnmodifiableMapView(artistNamesById),
       statusCountsByArtistId = UnmodifiableMapView(
         statusCountsByArtistId.map(
           (key, value) => MapEntry(key, UnmodifiableMapView(value)),
         ),
       );

  final int totalCount;
  final Map<int, int> countsByArtistId;
  final Map<String, int> countsByArtistName;
  final Map<int, String> artistNamesById;
  final Map<int, Map<String, int>> statusCountsByArtistId;

  factory VoteItemRequestCountSummary.fromRows(List<dynamic> rows) {
    var totalCount = 0;
    final countsByArtistId = <int, int>{};
    final countsByArtistName = <String, int>{};
    final artistNamesById = <int, String>{};
    final statusCountsByArtistId = <int, Map<String, int>>{};

    for (final raw in rows) {
      if (raw is! Map) continue;
      final artistId = raw['artist_id'];
      final artistName = raw['artist_name'];
      final status = raw['request_status'];
      final count = raw['request_count'];
      if (artistId is! int ||
          artistName is! String ||
          artistName.trim().isEmpty ||
          status is! String ||
          status.trim().isEmpty ||
          count is! int ||
          count < 0) {
        continue;
      }
      totalCount += count;
      countsByArtistId[artistId] = (countsByArtistId[artistId] ?? 0) + count;
      countsByArtistName[artistName] =
          (countsByArtistName[artistName] ?? 0) + count;
      artistNamesById.putIfAbsent(artistId, () => artistName);
      final statuses = statusCountsByArtistId.putIfAbsent(
        artistId,
        () => <String, int>{},
      );
      statuses[status] = (statuses[status] ?? 0) + count;
    }

    return VoteItemRequestCountSummary._(
      totalCount: totalCount,
      countsByArtistId: countsByArtistId,
      countsByArtistName: countsByArtistName,
      artistNamesById: artistNamesById,
      statusCountsByArtistId: statusCountsByArtistId,
    );
  }
}
