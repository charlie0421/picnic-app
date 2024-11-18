import 'package:picnic_app/repositories/compatibility_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/compatibility_repository_provider.g.dart';

@riverpod
CompatibilityRepository compatibilityRepository(
    CompatibilityRepositoryRef ref) {
  return CompatibilityRepository();
}
