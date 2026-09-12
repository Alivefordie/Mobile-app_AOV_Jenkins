import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/models/recipe_step.dart';
import 'package:flutter_application_1/widgets/cooking_steps/recipe_video_player.dart';

class CookingStepCard extends StatelessWidget {
  const CookingStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isCompleted,
    required this.isActive,
  });

  final RecipeStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _resolveMediaUrl(step.mediaUrl);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 34, bottom: 20),
          padding: const EdgeInsets.fromLTRB(24, 58, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25205D).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  isCompleted
                      ? 'เสร็จแล้ว'
                      : 'ขั้นตอน $stepNumber จาก $totalSteps',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF24BDB8)
                        : const Color(0xFF77729C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(contentType: step.contentType),
                      const SizedBox(height: 12),
                      Text(
                        step.sectionTitle,
                        style: const TextStyle(
                          color: Color(0xFF6D55A5),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: Color(0xFF25243A),
                          fontSize: 25,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: Color(0xFF69677A),
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      if (step.contentType == 'video' && mediaUrl != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: RecipeVideoPlayer(
                            url: mediaUrl,
                            isActive: isActive,
                          ),
                        ),
                      ] else if (step.contentType == 'video') ...[
                        const SizedBox(height: 20),
                        const _MissingVideo(),
                      ] else if (mediaUrl != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              mediaUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const _ImageFallback(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (step.durationSeconds != null) ...[
                const SizedBox(height: 14),
                _DurationChip(seconds: step.durationSeconds!),
              ],
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF24BDB8)
                : const Color(0xFFFF6847),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    (isCompleted
                            ? const Color(0xFF24BDB8)
                            : const Color(0xFFFF6847))
                        .withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : Icons.restaurant_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
      ],
    );
  }

  String? _resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme ?? false) return value;
    final base = ApiConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${value.startsWith('/') ? value : '/$value'}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.contentType});

  final String contentType;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (contentType) {
      'tip' => (
        Icons.lightbulb_outline_rounded,
        'เคล็ดลับ',
        const Color(0xFFFFA726),
      ),
      'warning' => (
        Icons.warning_amber_rounded,
        'ข้อควรระวัง',
        const Color(0xFFE95757),
      ),
      'video' => (
        Icons.play_circle_outline_rounded,
        'วิดีโอ',
        const Color(0xFF7B61C8),
      ),
      _ => (Icons.menu_book_rounded, 'วิธีทำ', const Color(0xFF24BDB8)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final label = minutes > 0
        ? '$minutes นาที${remainingSeconds > 0 ? ' $remainingSeconds วินาที' : ''}'
        : '$remainingSeconds วินาที';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF6D55A5)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF1EFF8),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 42,
          color: Color(0xFFAAA5C4),
        ),
      ),
    );
  }
}

class _MissingVideo extends StatelessWidget {
  const _MissingVideo();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Color(0xFF242230),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 42,
                color: Colors.white70,
              ),
              SizedBox(height: 8),
              Text(
                'ขั้นตอนนี้ยังไม่มีวิดีโอ',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
