import 'package:flutter_application_1/models/banner_item.dart';

abstract class BannerState {
  BannerState();
}

class BannerInitial extends BannerState {
  BannerInitial();
}

class BannerLoading extends BannerState {
  BannerLoading();
}

class BannerLoaded extends BannerState {
  final List<BannerItem> banners;
  BannerLoaded(this.banners);
}

class BannerError extends BannerState {
  final String message;
  BannerError({required this.message});
}
