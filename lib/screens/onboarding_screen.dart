import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  final Future<void> Function(String style) onStyleSelected;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.onStyleSelected,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController(viewportFraction: 0.88);
  late final AnimationController _previewController;
  late final Animation<Offset> _verticalOut;
  late final Animation<Offset> _verticalIn;
  late final Animation<Offset> _horizontalOut;
  late final Animation<Offset> _horizontalIn;
  int _page = 0;
  String? _selectedStyle;

  static const _featureCards = [
    _CardData(
      icon: Icons.menu_book_outlined,
      headline: 'Read in chunks.',
      body: 'Skip doomscrolling, read great books one passage at a time. '
          'No pressure to finish, just read.',
    ),
    _CardData(
      icon: Icons.local_fire_department_outlined,
      headline: 'Build a streak.',
      body: 'Open the App instead of doomscrolling, watch your streak grow.',
    ),
    _CardData(
      icon: Icons.account_balance_outlined,
      headline: 'The classics, free.',
      body: 'Six of the greatest books ever written. Yours, at no cost.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
    _verticalOut = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _verticalIn = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
    _horizontalOut =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
            .animate(CurvedAnimation(
                parent: _previewController,
                curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _horizontalIn = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _previewController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await widget.onStyleSelected(_selectedStyle!);
    await widget.onComplete();
    if (mounted) context.go('/app/library');
  }

  @override
  Widget build(BuildContext context) {
    final totalCards = _featureCards.length + 1;
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: totalCards,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, index) {
            final isStylePicker = index == _featureCards.length;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: isStylePicker
                    ? _buildStylePickerCard(totalCards)
                    : _buildFeatureCard(index, totalCards),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard(int index, int totalCards) {
    final card = _featureCards[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Icon(card.icon, size: 56, color: AppTheme.amber),
        const SizedBox(height: 32),
        Text(
          card.headline,
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          card.body,
          style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.tobacco),
        ),
        const Spacer(),
        _DotRow(current: index, total: totalCards),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStylePickerCard(int totalCards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'How do you like to read?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pick a style. You can change it any time in Settings.',
          style: GoogleFonts.dmSans(fontSize: 16, color: AppTheme.tobacco),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StyleTile(
                label: 'Swipe down',
                subLabel: 'Scroll Style',
                selected: _selectedStyle == 'vertical',
                slideOut: _verticalOut,
                slideIn: _verticalIn,
                onTap: () => setState(() => _selectedStyle = 'vertical'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StyleTile(
                label: 'Tap across',
                subLabel: 'Stories Style',
                selected: _selectedStyle == 'horizontal',
                slideOut: _horizontalOut,
                slideIn: _horizontalIn,
                onTap: () => setState(() => _selectedStyle = 'horizontal'),
              ),
            ),
          ],
        ),
        const Spacer(),
        _DotRow(current: _featureCards.length, total: totalCards),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedStyle != null ? _complete : null,
            child: const Text('Start reading →'),
          ),
        ),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool selected;
  final Animation<Offset> slideOut;
  final Animation<Offset> slideIn;
  final VoidCallback onTap;

  const _StyleTile({
    required this.label,
    required this.subLabel,
    required this.selected,
    required this.slideOut,
    required this.slideIn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.amber : AppTheme.fog,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRect(
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    SlideTransition(
                        position: slideOut, child: const _MiniReaderCard()),
                    SlideTransition(
                        position: slideIn, child: const _MiniReaderCard()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink),
            ),
            Text(
              subLabel,
              style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.pewter),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReaderCard extends StatelessWidget {
  const _MiniReaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.amberWash,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.fog,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.fog,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Container(
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.fog,
                    borderRadius: BorderRadius.circular(2))),
          ),
        ],
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final int current;
  final int total;
  const _DotRow({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: current == i ? AppTheme.amber : AppTheme.fog,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _CardData {
  final IconData icon;
  final String headline;
  final String body;
  const _CardData(
      {required this.icon, required this.headline, required this.body});
}
