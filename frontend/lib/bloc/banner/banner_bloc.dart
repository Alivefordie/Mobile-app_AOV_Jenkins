import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_event.dart';
import 'package:flutter_application_1/bloc/banner/banner_state.dart';
import 'package:flutter_application_1/repositories/banner_repository.dart';

class BannerBloc extends Bloc<BannerEvent, BannerState> {
  final BannerRepository repository;

  BannerBloc(this.repository) : super(BannerInitial()) {
    on<FetchBannersEvent>(_onFetchBannersEvent);
  }

  Future<void> _onFetchBannersEvent(
    FetchBannersEvent event,
    Emitter<BannerState> emit,
  ) async {
    emit(BannerLoading());
    try {
      final banners = await repository.fetchBanners();
      emit(BannerLoaded(banners));
    } catch (e) {
      emit(BannerError(message: e.toString()));
    }
  }
}
