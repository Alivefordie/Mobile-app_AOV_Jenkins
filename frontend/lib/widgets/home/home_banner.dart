import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_bloc.dart';
import 'package:flutter_application_1/bloc/banner/banner_state.dart';
import 'package:flutter_application_1/models/banner_item.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, state) {
        if (state is BannerLoading || state is BannerInitial) {
          return const _BannerFrame(child: _BannerPlaceholder());
        }

        // โหลดไม่สำเร็จ หรือยังไม่มีแบนเนอร์ = ซ่อนไปเลย
        if (state is! BannerLoaded || state.banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return _BannerCarousel(banners: state.banners);
      },
    );
  }
}

/// กรอบการ์ดของแบนเนอร์ (กำหนดความสูงตามขนาดจอ)
class _BannerFrame extends StatelessWidget {
  const _BannerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // < 600 มือถือ, >= 600 iPad
        final isMedium = constraints.maxWidth >= 600;

        return Card(
          elevation: 6,
          shadowColor: const Color(0xFFE64A19).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: isMedium ? 260.0 : 206.0,
            width: double.infinity,
            child: child,
          ),
        );
      },
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey.shade200);
  }
}

/// สไลด์โชว์รูปแบนเนอร์ เลื่อนเองทุก 4 วิ และปัดเองได้
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners});

  final List<BannerItem> banners;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  static const _autoScrollInterval = Duration(seconds: 4);
  static const _animationDuration = Duration(milliseconds: 450);

  final PageController _controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _restartAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      if (_currentIndex >= widget.banners.length) {
        _currentIndex = 0;
        if (_controller.hasClients) _controller.jumpToPage(0);
      }
      _restartAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAutoScroll() {
    _timer?.cancel();
    // มีรูปเดียวก็ไม่ต้องเลื่อน
    if (widget.banners.length < 2) return;

    _timer = Timer.periodic(_autoScrollInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_currentIndex + 1) % widget.banners.length;
      _controller.animateToPage(
        nextIndex,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BannerFrame(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (_, index) => _BannerImage(
              imageUrl: widget.banners[index].imageUrl,
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              final isActive = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isActive ? 20 : 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFD32F2F)
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _BannerPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade500,
          size: 40,
        ),
      ),
    );
  }
}
