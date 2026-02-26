import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController(viewportFraction: 0.88);
  int _page = 0;

  static const _cards = [
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await widget.onComplete();
    if (mounted) context.go('/app/library');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isLast = index == _cards.length - 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
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
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              color: AppTheme.tobacco,
                            ),
                          ),
                          const Spacer(),
                          if (isLast)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _complete,
                                child: const Text('Start reading →'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _cards.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 8,
                    height: _page == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _page == i ? AppTheme.amber : AppTheme.fog,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
