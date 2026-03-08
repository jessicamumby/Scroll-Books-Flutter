import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class SharedHeader extends StatelessWidget {
  final String heading;
  const SharedHeader({super.key, required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCROLL BOOKS',
            style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
          ),
          const SizedBox(height: 4),
          Text(
            heading,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
