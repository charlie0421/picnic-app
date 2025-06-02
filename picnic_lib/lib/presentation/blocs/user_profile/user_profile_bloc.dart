import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';
import 'package:picnic_lib/application/use_cases/user/get_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/update_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/manage_star_candy_use_case.dart';
import 'package:picnic_lib/application/common/use_case_result.dart';
import 'package:picnic_lib/core/utils/logger.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';
part 'user_profile_bloc.freezed.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final ManageStarCandyUseCase _manageStarCandyUseCase;

  UserProfileBloc({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required ManageStarCandyUseCase manageStarCandyUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserProfileUseCase = updateUserProfileUseCase,
        _manageStarCandyUseCase = manageStarCandyUseCase,
        super(const UserProfileState.initial()) {
    on<UserProfileEvent>(
      (event, emit) async {
        await event.when(
          loadUserProfile: (userId, requireCompleteProfile, requireAgreement) =>
              _onLoadUserProfile(emit, userId, requireCompleteProfile, requireAgreement),
          updateProfile: (userId, nickname, avatarUrl, birthDate, gender, birthTime) =>
              _onUpdateProfile(emit, userId, nickname, avatarUrl, birthDate, gender, birthTime),
          addStarCandy: (userId, amount, reason) =>
              _onAddStarCandy(emit, userId, amount, reason),
          spendStarCandy: (userId, amount, reason) =>
              _onSpendStarCandy(emit, userId, amount, reason),
          refresh: (userId) => _onRefresh(emit, userId),
        );
      },
    );
  }

  Future<void> _onLoadUserProfile(
    Emitter<UserProfileState> emit,
    String userId,
    bool requireCompleteProfile,
    bool requireAgreement,
  ) async {
    try {
      emit(const UserProfileState.loading());

      final params = GetUserProfileParams(
        userId: userId,
        requireCompleteProfile: requireCompleteProfile,
        requireAgreement: requireAgreement,
      );

      final result = await _getUserProfileUseCase.execute(params);

      result.when(
        success: (user) {
          if (user != null) {
            emit(UserProfileState.loaded(user: user));
          } else {
            emit(const UserProfileState.error(message: 'User not found'));
          }
        },
        failure: (failure) {
          logger.e('Failed to load user profile', error: failure.message);
          emit(UserProfileState.error(message: failure.message));
        },
      );
    } catch (e) {
      logger.e('Unexpected error loading user profile', error: e);
      emit(UserProfileState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onUpdateProfile(
    Emitter<UserProfileState> emit,
    String userId,
    String? nickname,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  ) async {
    try {
      final currentState = state;
      if (currentState is! UserProfileLoaded) {
        emit(const UserProfileState.error(message: 'No user profile loaded'));
        return;
      }

      emit(UserProfileState.loading(user: currentState.user));

      final params = UpdateUserProfileParams(
        userId: userId,
        nickname: nickname,
        avatarUrl: avatarUrl,
        birthDate: birthDate,
        gender: gender,
        birthTime: birthTime,
      );

      final result = await _updateUserProfileUseCase.execute(params);

      result.when(
        success: (updatedUser) {
          emit(UserProfileState.loaded(user: updatedUser));
          logger.i('User profile updated successfully');
        },
        failure: (failure) {
          logger.e('Failed to update user profile', error: failure.message);
          emit(UserProfileState.error(
            message: failure.message,
            user: currentState.user,
          ));
        },
      );
    } catch (e) {
      logger.e('Unexpected error updating user profile', error: e);
      emit(UserProfileState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onAddStarCandy(
    Emitter<UserProfileState> emit,
    String userId,
    StarCandy amount,
    String reason,
  ) async {
    try {
      final currentState = state;
      if (currentState is! UserProfileLoaded) {
        emit(const UserProfileState.error(message: 'No user profile loaded'));
        return;
      }

      emit(UserProfileState.loading(user: currentState.user));

      final params = ManageStarCandyParams(
        userId: userId,
        amount: amount,
        transactionType: StarCandyTransactionType.add,
        reason: reason,
      );

      final result = await _manageStarCandyUseCase.execute(params);

      result.when(
        success: (transactionResult) {
          emit(UserProfileState.loaded(user: transactionResult.user));
          logger.i('Star candy added successfully: ${amount.displayText}');
        },
        failure: (failure) {
          logger.e('Failed to add star candy', error: failure.message);
          emit(UserProfileState.error(
            message: failure.message,
            user: currentState.user,
          ));
        },
      );
    } catch (e) {
      logger.e('Unexpected error adding star candy', error: e);
      emit(UserProfileState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onSpendStarCandy(
    Emitter<UserProfileState> emit,
    String userId,
    StarCandy amount,
    String reason,
  ) async {
    try {
      final currentState = state;
      if (currentState is! UserProfileLoaded) {
        emit(const UserProfileState.error(message: 'No user profile loaded'));
        return;
      }

      emit(UserProfileState.loading(user: currentState.user));

      final params = ManageStarCandyParams(
        userId: userId,
        amount: amount,
        transactionType: StarCandyTransactionType.spend,
        reason: reason,
      );

      final result = await _manageStarCandyUseCase.execute(params);

      result.when(
        success: (transactionResult) {
          emit(UserProfileState.loaded(user: transactionResult.user));
          logger.i('Star candy spent successfully: ${amount.displayText}');
        },
        failure: (failure) {
          logger.e('Failed to spend star candy', error: failure.message);
          emit(UserProfileState.error(
            message: failure.message,
            user: currentState.user,
          ));
        },
      );
    } catch (e) {
      logger.e('Unexpected error spending star candy', error: e);
      emit(UserProfileState.error(message: 'Unexpected error: $e'));
    }
  }

  Future<void> _onRefresh(
    Emitter<UserProfileState> emit,
    String userId,
  ) async {
    try {
      final params = GetUserProfileParams(userId: userId);
      final result = await _getUserProfileUseCase.execute(params);

      result.when(
        success: (user) {
          if (user != null) {
            emit(UserProfileState.loaded(user: user));
          } else {
            emit(const UserProfileState.error(message: 'User not found'));
          }
        },
        failure: (failure) {
          logger.e('Failed to refresh user profile', error: failure.message);
          emit(UserProfileState.error(message: failure.message));
        },
      );
    } catch (e) {
      logger.e('Unexpected error refreshing user profile', error: e);
      emit(UserProfileState.error(message: 'Unexpected error: $e'));
    }
  }
}