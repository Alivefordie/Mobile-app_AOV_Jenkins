import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/repositories/profile_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      super(const ProfileInitial()) {
    on<ProfileRequested>(_loadProfile);
    on<ProfileRefreshRequested>(_loadProfile);
  }

  final ProfileRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _loadProfile(
    ProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      emit(const ProfileGuest());
      return;
    }

    if (event is ProfileRequested || state is! ProfileLoaded) {
      emit(const ProfileLoading());
    }
    try {
      final profile = await _repository.fetchProfile(accessToken);
      emit(ProfileLoaded(profile));
    } on Exception catch (error) {
      emit(ProfileFailure(error.toString()));
    }
  }
}
