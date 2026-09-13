import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_application_1/repositories/token_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// อ่าน userId + token จาก secure storage เองแบบเดียวกับ ProfileBloc
class RecipeLibraryBloc extends Bloc<RecipeLibraryEvent, RecipeLibraryState> {
  RecipeLibraryBloc(
    this._repository, {
    required this.collectionType,
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage(),
       super(const RecipeLibraryInitial()) {
    on<RecipeLibraryRequested>(_load);
    on<RecipeLibraryRefreshRequested>(_load);
  }

  final RecipeLibraryRepository _repository;
  final TokenStorage _tokenStorage;
  final RecipeCollectionType collectionType;

  Future<void> _load(
    RecipeLibraryEvent event,
    Emitter<RecipeLibraryState> emit,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    final userId = await _tokenStorage.readUserId();

    if (accessToken == null || userId == null) {
      emit(const RecipeLibraryFailure('Please sign in to see your recipes.'));
      return;
    }

    if (event is RecipeLibraryRequested || state is! RecipeLibraryLoaded) {
      emit(const RecipeLibraryLoading());
    }

    try {
      final recipes = await _repository.fetchCollection(
        collectionType,
        userId: userId,
        accessToken: accessToken,
      );
      emit(RecipeLibraryLoaded(recipes));
    } on Exception catch (error) {
      emit(RecipeLibraryFailure(error.toString()));
    }
  }
}
