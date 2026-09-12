import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_bloc.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_event.dart';
import 'package:flutter_application_1/bloc/recipe_library/recipe_library_state.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/views/pages/food_detail_page.dart';
import 'package:flutter_application_1/widgets/profile/profile_colors.dart';
import 'package:flutter_application_1/widgets/recipe_library/recipe_library_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecipeCollectionPage extends StatelessWidget {
  const RecipeCollectionPage({super.key, required this.collectionType});

  final RecipeCollectionType collectionType;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<RecipeLibraryBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is RecipeLibraryLoaded || state is RecipeLibraryFailure,
    );
    bloc.add(const RecipeLibraryRefreshRequested());
    await completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: ProfileColors.background,
        foregroundColor: ProfileColors.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          collectionType.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<RecipeLibraryBloc, RecipeLibraryState>(
        builder: (context, state) {
          return switch (state) {
            RecipeLibraryLoaded(:final recipes) when recipes.isEmpty =>
              _EmptyView(
                message: collectionType.emptyMessage,
                onRefresh: () => _refresh(context),
              ),
            RecipeLibraryLoaded(:final recipes) => RefreshIndicator(
              color: ProfileColors.ink,
              onRefresh: () => _refresh(context),
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.67,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return RecipeLibraryCard(
                    recipe: recipe,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => FoodDetailPage(foodsId: recipe.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            RecipeLibraryFailure(:final message) => _ErrorView(
              message: message,
              onRetry: () => context.read<RecipeLibraryBloc>().add(
                const RecipeLibraryRequested(),
              ),
            ),
            _ => const Center(
              child: CircularProgressIndicator(color: ProfileColors.ink),
            ),
          };
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message, required this.onRefresh});

  final String message;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ProfileColors.ink,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.menu_book_rounded,
            color: ProfileColors.muted,
            size: 56,
          ),
          const SizedBox(height: 18),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ProfileColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ProfileColors.muted,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ProfileColors.muted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
