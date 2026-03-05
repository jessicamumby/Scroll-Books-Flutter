import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class PassageShareCard extends StatelessWidget {
  final String passageText;
  final String bookTitle;
  final String author;
  final String pageLabel;

  const PassageShareCard({
    super.key,
    required this.passageText,
    required this.bookTitle,
    required this.author,
    required this.pageLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      color: AppTheme.page,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book metadata
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bookTitle,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                author,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppTheme.tobacco,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Passage text
          Expanded(
            child: Text(
              passageText,
              style: GoogleFonts.lora(
                fontSize: 16,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: AppTheme.ink,
              ),
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          // Bottom: branding + page label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                  children: [
                    const TextSpan(text: 'scroll'),
                    TextSpan(
                      text: '.',
                      style: TextStyle(color: AppTheme.brand),
                    ),
                    const TextSpan(text: 'books'),
                  ],
                ),
              ),
              Text(
                pageLabel,
                style: GoogleFonts.dmMono(
                  fontSize: 11,
                  color: AppTheme.tobacco,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
