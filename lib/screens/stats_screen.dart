import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../utils/streak_calculator.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final streak = calculateStreak(provider.readDays);
        final now = DateTime.now();
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

        return Scaffold(
          backgroundColor: AppTheme.page,
          appBar: AppBar(title: const Text('Stats')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '$streak',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.brand,
                    ),
                  ),
                  Text(
                    'day streak',
                    style: TextStyle(fontSize: 16, color: AppTheme.tobacco),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '${_monthName(now.month)} ${now.year}',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (_, i) {
                      final day = i + 1;
                      final dateStr =
                          '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                      final read = provider.readDays.contains(dateStr);
                      return Container(
                        decoration: BoxDecoration(
                          color: read ? AppTheme.brand : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              color: read ? AppTheme.surface : AppTheme.pewter,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}
