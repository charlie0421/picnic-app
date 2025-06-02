import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picnic_lib/core/di/service_locator.dart';
import 'package:picnic_lib/presentation/blocs/user_profile/user_profile_bloc.dart';
import 'package:picnic_lib/presentation/blocs/artist/artist_bloc.dart';
import 'package:picnic_lib/application/use_cases/user/get_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/update_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/manage_star_candy_use_case.dart';
import 'package:picnic_lib/application/use_cases/artist/get_artist_use_case.dart';
import 'package:picnic_lib/application/use_cases/artist/vote_for_artist_use_case.dart';

/// Provides all BLoC instances for the application
class BlocProviders {
  /// Create a multi-BlocProvider with all application BLoCs
  static Widget provideBlocs({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserProfileBloc>(
          create: (context) => UserProfileBloc(
            getUserProfileUseCase: ServiceLocator.get<GetUserProfileUseCase>(),
            updateUserProfileUseCase: ServiceLocator.get<UpdateUserProfileUseCase>(),
            manageStarCandyUseCase: ServiceLocator.get<ManageStarCandyUseCase>(),
          ),
        ),
        BlocProvider<ArtistBloc>(
          create: (context) => ArtistBloc(
            getArtistUseCase: ServiceLocator.get<GetArtistUseCase>(),
            voteForArtistUseCase: ServiceLocator.get<VoteForArtistUseCase>(),
          ),
        ),
      ],
      child: child,
    );
  }

  /// Create a specific BLoC provider for lazy initialization
  static BlocProvider<UserProfileBloc> userProfileBlocProvider({
    required Widget child,
  }) {
    return BlocProvider<UserProfileBloc>(
      create: (context) => UserProfileBloc(
        getUserProfileUseCase: ServiceLocator.get<GetUserProfileUseCase>(),
        updateUserProfileUseCase: ServiceLocator.get<UpdateUserProfileUseCase>(),
        manageStarCandyUseCase: ServiceLocator.get<ManageStarCandyUseCase>(),
      ),
      child: child,
    );
  }

  /// Create a specific BLoC provider for Artist
  static BlocProvider<ArtistBloc> artistBlocProvider({
    required Widget child,
  }) {
    return BlocProvider<ArtistBloc>(
      create: (context) => ArtistBloc(
        getArtistUseCase: ServiceLocator.get<GetArtistUseCase>(),
        voteForArtistUseCase: ServiceLocator.get<VoteForArtistUseCase>(),
      ),
      child: child,
    );
  }

  /// Initialize BLoCs in the service locator (alternative approach)
  static void registerBlocs() {
    // Register BLoC factories in ServiceLocator
    ServiceLocator._getIt.registerFactory<UserProfileBloc>(
      () => UserProfileBloc(
        getUserProfileUseCase: ServiceLocator.get<GetUserProfileUseCase>(),
        updateUserProfileUseCase: ServiceLocator.get<UpdateUserProfileUseCase>(),
        manageStarCandyUseCase: ServiceLocator.get<ManageStarCandyUseCase>(),
      ),
    );

    ServiceLocator._getIt.registerFactory<ArtistBloc>(
      () => ArtistBloc(
        getArtistUseCase: ServiceLocator.get<GetArtistUseCase>(),
        voteForArtistUseCase: ServiceLocator.get<VoteForArtistUseCase>(),
      ),
    );
  }
}

/// Mixin for widgets that need access to BLoCs
mixin BlocAccessMixin<T extends StatefulWidget> on State<T> {
  /// Get UserProfile BLoC from context
  UserProfileBloc get userProfileBloc => context.read<UserProfileBloc>();

  /// Get Artist BLoC from context
  ArtistBloc get artistBloc => context.read<ArtistBloc>();
}

/// Extension for easy BLoC access in BuildContext
extension BlocContextExtension on BuildContext {
  /// Get UserProfile BLoC
  UserProfileBloc get userProfileBloc => read<UserProfileBloc>();

  /// Get Artist BLoC
  ArtistBloc get artistBloc => read<ArtistBloc>();

  /// Watch UserProfile BLoC
  UserProfileBloc get watchUserProfileBloc => watch<UserProfileBloc>();

  /// Watch Artist BLoC
  ArtistBloc get watchArtistBloc => watch<ArtistBloc>();
}