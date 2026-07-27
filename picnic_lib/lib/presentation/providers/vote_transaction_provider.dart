import 'package:picnic_lib/data/repositories/vote_transaction_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/vote_transaction_provider.g.dart';

@Riverpod(keepAlive: true)
VoteTransactionRepository voteTransactionRepository(Ref ref) {
  return VoteTransactionRepository(supabase);
}
