import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ReaderCard extends StatelessWidget {
  final String text;
  final VoidCallback onShare;

  const ReaderCard({super.key, required this.text, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.page,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        height: 1.75,
                        color: AppTheme.ink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.share_outlined),
                  color: AppTheme.pewter,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
