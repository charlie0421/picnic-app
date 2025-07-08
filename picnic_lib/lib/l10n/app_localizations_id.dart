// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Piknik';

  @override
  String get vote_item_request_title => 'Vote Candidate Application';

  @override
  String get vote_item_request_button => 'Ajukan Voting';

  @override
  String get artist_name_label => 'Nama Artis';

  @override
  String get group_name_label => 'Nama Grup';

  @override
  String get application_reason_label => 'Alasan Aplikasi';

  @override
  String get artist_name_hint => 'Masukkan nama artis';

  @override
  String get group_name_hint => 'Masukkan nama grup (opsional)';

  @override
  String get application_reason_hint => 'Masukkan alasan aplikasi (opsional)';

  @override
  String get submit_application => 'Kirim Aplikasi';

  @override
  String get vote_item_request_search_artist_hint =>
      'Search for artist or group';

  @override
  String get application_success => 'Aplikasi kandidat voting telah selesai.';

  @override
  String get success => 'Berhasil';

  @override
  String get vote_period => 'Periode Voting';

  @override
  String get error_artist_not_selected => 'Silakan pilih artis';

  @override
  String get error_application_reason_required => 'Alasan aplikasi diperlukan';

  @override
  String get searching => 'Mencari...';

  @override
  String get no_search_results => 'No search results found';

  @override
  String get vote_item_request_current_item_request =>
      'Permintaan Item Saat Ini';

  @override
  String get vote_item_request_no_item_request_yet =>
      'Belum ada permintaan item';

  @override
  String get vote_item_request_search_artist => 'Search Artist';

  @override
  String get vote_item_request_search_artist_prompt =>
      'Cari artis untuk melamar';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count permintaan item';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return 'Total $count permintaan item';
  }

  @override
  String get vote_item_request_submit => 'Ajukan';

  @override
  String get vote_item_request_already_registered => 'Sudah terdaftar';

  @override
  String get vote_item_request_can_apply => 'Can apply';

  @override
  String get vote_item_request_status_pending => 'Menunggu';

  @override
  String get vote_item_request_status_approved => 'Disetujui';

  @override
  String get vote_item_request_status_rejected => 'Ditolak';

  @override
  String get vote_item_request_status_in_progress => 'In Progress';

  @override
  String get vote_item_request_status_cancelled => 'Cancelled';

  @override
  String get vote_item_request_status_unknown => 'Unknown';

  @override
  String get vote_item_request_artist_name_missing => 'Nama artis hilang';

  @override
  String get vote_item_request_user_info_not_found =>
      'Informasi pengguna tidak ditemukan.';

  @override
  String get vote_item_request_already_applied_artist =>
      'You have already applied for this artist.';

  @override
  String get vote_item_request_addition_request =>
      'Permintaan penambahan item voting';

  @override
  String get label_tabbar_vote_active => 'Active';

  @override
  String get label_tabbar_vote_image => 'Voting Gambar';

  @override
  String get label_tabbar_vote_end => 'Ended';

  @override
  String get label_tabbar_vote_upcoming => 'Upcoming';
}
