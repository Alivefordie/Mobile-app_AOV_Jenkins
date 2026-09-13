import 'package:flutter/material.dart';
import 'package:flutter_application_1/bloc/cart/cart_bloc.dart';
import 'package:flutter_application_1/bloc/cart/cart_event.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_bloc.dart';
import 'package:flutter_application_1/bloc/favorite/favorite_event.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/repositories/cart_repository.dart';
import 'package:flutter_application_1/repositories/favorite_repository.dart';
import 'package:flutter_application_1/routes/app_routes.dart';
import 'package:flutter_application_1/routes/route_generator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ตะกร้ากับหัวใจถูกใช้ข้ามหน้า (home, community, cart, profile)
    // และ CartPage ถูก push เป็น route ใหม่ จึงต้องวาง provider ไว้เหนือ MaterialApp
    // ทั้งสอง bloc อ่าน token จาก secure storage เอง ไม่ต้องส่ง userId ให้
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CartBloc(
            HttpCartRepository(baseUrl: ApiConfig.apiBaseUrl),
          )..add(const CartRequested()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc(
            HttpFavoriteRepository(baseUrl: ApiConfig.apiBaseUrl),
          )..add(const FavoritesRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: (settings) => RoutesGenerator.generateRoute(settings),
      ),
    );
  }
}
