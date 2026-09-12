import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/profile/profile_bloc.dart';
import 'package:flutter_application_1/bloc/profile/profile_event.dart';
import 'package:flutter_application_1/bloc/profile/profile_state.dart';
import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/models/recipe_collection_type.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/widgets/profile/profile_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature is coming soon'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ProfileColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is ProfileLoaded || state is ProfileFailure,
    );
    bloc.add(const ProfileRefreshRequested());
    await completed;
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in at any time to access your recipes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showComingSoon(context, 'Sign out');
            },
            style: FilledButton.styleFrom(backgroundColor: ProfileColors.ink),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  void _openRecipeCollection(
    BuildContext context,
    RecipeCollectionType collectionType,
  ) {
    final routeName = switch (collectionType) {
      RecipeCollectionType.myRecipes => AppRoutes.myRecipes,
      RecipeCollectionType.purchased => AppRoutes.purchasedRecipes,
      RecipeCollectionType.favorites => AppRoutes.favoriteRecipes,
      RecipeCollectionType.drafts => AppRoutes.draftRecipes,
    };
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.background,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileLoaded(:final profile) => _ProfileContent(
                profile: profile,
                onRefresh: () => _refresh(context),
                onActionPressed: (label) => _showComingSoon(context, label),
                onRecipeCollectionPressed: (collectionType) =>
                    _openRecipeCollection(context, collectionType),
                onSignOut: () => _confirmSignOut(context),
                onCartPressed: () => _openCart(context),
              ),
              ProfileFailure(:final message) => ProfileErrorView(
                message: message,
                onRetry: () =>
                    context.read<ProfileBloc>().add(const ProfileRequested()),
              ),
              _ => const ProfileLoadingView(),
            };
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onRefresh,
    required this.onActionPressed,
    required this.onRecipeCollectionPressed,
    required this.onSignOut,
    required this.onCartPressed,
  });

  final UserProfile profile;
  final RefreshCallback onRefresh;
  final ValueChanged<String> onActionPressed;
  final ValueChanged<RecipeCollectionType> onRecipeCollectionPressed;
  final VoidCallback onSignOut;
  final VoidCallback onCartPressed;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ProfileColors.ink,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList.list(
              children: [
                ProfilePageHeader(
                  onSettingsPressed: () => onActionPressed('Settings'),
                  onCartPressed: onCartPressed,
                ),
                const SizedBox(height: 22),
                ProfileCard(
                  profile: profile,
                  onEditPressed: () => onActionPressed('Edit profile'),
                ),
                const SizedBox(height: 16),
                ProfileStatsRow(profile: profile),
                const SizedBox(height: 30),
                const ProfileSectionTitle(
                  title: 'Your kitchen',
                  subtitle: 'Everything you cook and collect',
                ),
                const SizedBox(height: 14),
                ProfileQuickActions(
                  profile: profile,
                  onPressed: onRecipeCollectionPressed,
                ),
                const SizedBox(height: 30),
                const ProfileSectionTitle(
                  title: 'Account',
                  subtitle: 'Manage your preferences',
                ),
                const SizedBox(height: 14),
                ProfileAccountMenu(
                  onPressed: onActionPressed,
                  onSignOut: onSignOut,
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Recipy · Version 1.0.0',
                    style: TextStyle(
                      color: ProfileColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
