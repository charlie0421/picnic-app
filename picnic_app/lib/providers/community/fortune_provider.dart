import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/fortune.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/fortune_provider.g.dart';

@riverpod
Future<FortuneModel> getFortune(
  Ref ref, {
  required int artistId,
  required int year,
}) async {
  final fortune = await supabase
      .from("fortune_telling")
      .select()
      .eq('artist_id', artistId)
      .eq('year', year)
      .maybeSingle();

  return FortuneModel.fromJson(fortune!);
}
