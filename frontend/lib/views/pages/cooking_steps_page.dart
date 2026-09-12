import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/food.dart';
import 'package:flutter_application_1/widgets/cooking_steps/cooking_step_card.dart';

class CookingStepsPage extends StatefulWidget {
  const CookingStepsPage({super.key, required this.food});

  final Food food;

  @override
  State<CookingStepsPage> createState() => _CookingStepsPageState();
}

class _CookingStepsPageState extends State<CookingStepsPage> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final Set<int> _completedSteps = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.food.steps.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _completeOrContinue() {
    setState(() => _completedSteps.add(_currentIndex));
    if (_currentIndex < widget.food.steps.length - 1) {
      _goTo(_currentIndex + 1);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 58,
              color: Color(0xFFFF6847),
            ),
            const SizedBox(height: 12),
            const Text(
              'ทำอาหารเสร็จแล้ว!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('คุณทำ ${widget.food.name} ครบทุกขั้นตอนแล้ว'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('กลับไปหน้าสูตรอาหาร'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.food.steps;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6650A5), Color(0xFF769FDA), Color(0xFF83D5DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _CookingHeader(
                recipeName: widget.food.name,
                currentStep: steps.isEmpty ? 0 : _currentIndex + 1,
                totalSteps: steps.length,
                onClose: () => Navigator.pop(context),
              ),
              if (steps.isEmpty)
                const Expanded(child: _EmptySteps())
              else ...[
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: steps.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: CookingStepCard(
                        step: steps[index],
                        stepNumber: index + 1,
                        totalSteps: steps.length,
                        isCompleted: _completedSteps.contains(index),
                        isActive: index == _currentIndex,
                      ),
                    ),
                  ),
                ),
                _StepControls(
                  currentIndex: _currentIndex,
                  totalSteps: steps.length,
                  onPrevious: () => _goTo(_currentIndex - 1),
                  onContinue: _completeOrContinue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CookingHeader extends StatelessWidget {
  const _CookingHeader({
    required this.recipeName,
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  final String recipeName;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'กำลังทำอาหาร',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  recipeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$currentStep / $totalSteps ขั้นตอน',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ปิด',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepControls extends StatelessWidget {
  const _StepControls({
    required this.currentIndex,
    required this.totalSteps,
    required this.onPrevious,
    required this.onContinue,
  });

  final int currentIndex;
  final int totalSteps;
  final VoidCallback onPrevious;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: IconButton.filledTonal(
              tooltip: 'ขั้นตอนก่อนหน้า',
              onPressed: currentIndex == 0 ? null : onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 58,
              child: FilledButton.icon(
                key: const Key('complete-step-button'),
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF24BDB8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  isLast ? Icons.done_all_rounded : Icons.check_rounded,
                ),
                label: Text(
                  isLast ? 'ทำอาหารเสร็จแล้ว' : 'เสร็จขั้นตอนนี้',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySteps extends StatelessWidget {
  const _EmptySteps();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 54, color: Color(0xFF6D55A5)),
            SizedBox(height: 14),
            Text(
              'สูตรนี้ยังไม่มีขั้นตอนการทำ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
