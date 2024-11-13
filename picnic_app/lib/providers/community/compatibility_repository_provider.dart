import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:picnic_app/repositories/compatibility_repository.dart';

part 'compatibility_repository_provider.g.dart';

@riverpod
CompatibilityRepository compatibilityRepository(
    CompatibilityRepositoryRef ref) {
  return CompatibilityRepository();
}
