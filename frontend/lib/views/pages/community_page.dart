import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/bloc/category/category_event.dart';
import 'package:flutter_application_1/bloc/category/category_state.dart';
import 'package:flutter_application_1/widgets/community/category_card.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();

    final categoryBloc = context.read<CategoryBloc>();
    final state = categoryBloc.state;

    if (state is! CategoryLoaded &&
        state is! CategoryLoading) {
      categoryBloc.add(FetchCategoriesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIpad = MediaQuery.sizeOf(context).shortestSide >= 600;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoaded) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                children: [
                  SizedBox(
                    height: isIpad ? 14 : 9,
                  ),
                  Center(
                    child: Text(
                      'COMMUNITY',
                      style: TextStyle(
                        fontSize: isIpad ? 35 : 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...state.categories.map((category) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isIpad ? 20 : 12,
                      ),
                      child: CategoryCard(
                        category: category,
                      ),
                    );
                  }),
                ],
              );
            }

            if (state is CategoryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is CategoryError) {
              return Center(
                child: Text('Error: ${state.message}'),
              );
            }

            return const Center(
              child: Text('No data available.'),
            );
          },
        ),
      ),
    );
  }
}