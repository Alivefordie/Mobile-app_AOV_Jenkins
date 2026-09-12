import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/repositories/recipe_library_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipeLibraryBloc extends Bloc<RecipeLibraryEvent, RecipeLibraryState> {
  RecipeLibraryBloc(
    this._repository, {
    required this.userId,
    required this.collectionType,
  }) : super(const RecipeLibraryInitial()) {
    on<RecipeLibraryRequested>(_load);
    on<RecipeLibraryRefreshRequested>(_load);
  }

  final RecipeLibraryRepository _repository;
  final String userId;
  final RecipeCollectionType collectionType;

  Future<void> _load(
    RecipeLibraryEvent event,
    Emitter<RecipeLibraryState> emit,
  ) async {
    if (event is RecipeLibraryRequested || state is! RecipeLibraryLoaded) {
      emit(const RecipeLibraryLoading());
    }

    try {
      final recipes = await _repository.fetchCollection(collectionType, userId);
      emit(RecipeLibraryLoaded(recipes));
    } on Exception catch (error) {
      emit(RecipeLibraryFailure(error.toString()));
    }
  }
}
