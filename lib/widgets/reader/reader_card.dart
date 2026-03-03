import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class ReaderCard extends StatelessWidget {
  final String text;
  final int chunkIndex;
  final int totalChunks;

  const ReaderCard({
    super.key,
    required this.text,
    required this.chunkIndex,
    required this.totalChunks,
  });

  String get _pageLabel {
    final page = chunkIndex + 1;
    final pct = totalChunks > 0
        ? ((chunkIndex + 1) / totalChunks * 100).round()
        : 0;
    return 'p. $page · $pct%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.page,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.brandPale, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      text,
                                      style: GoogleFonts.lora(
                                        fontSize: 18,
                                        height: 1.75,
                                        color: AppTheme.ink,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _pageLabel,
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        color: AppTheme.tobacco,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
