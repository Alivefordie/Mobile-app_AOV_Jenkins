import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/category/category_bloc.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    const fallbackImage =
        'https://st2.depositphotos.com/3904951/8925/v/450/depositphotos_89250312-stock-illustration-photo-picture-web-icon-in.jpg';

    final rawImageUrl = category.imageUrl?.trim() ?? '';

    final imageUrl =
        rawImageUrl.isEmpty ? fallbackImage : rawImageUrl;

    return Card(
      elevation:
          MediaQuery.sizeOf(context).shortestSide >= 600
              ? 6
              : 5,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          MediaQuery.sizeOf(context).shortestSide >= 600
              ? 24
              : 20,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communitySelectCategory,
            arguments: {
              'categoryUUID': category.id,
              'categoryImageUrl': imageUrl,

              // ส่ง CategoryBloc ตัวเดิมไปด้วย
              'categoryBloc': context.read<CategoryBloc>(),
            },
          );
        },

        child: SizedBox(
          height:
              MediaQuery.sizeOf(context).shortestSide >= 600
                  ? 240
                  : 130,

          child: Image.network(
            imageUrl,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: BoxFit.cover,

            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Image.network(
                fallbackImage,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      ),
    );
  }
}