import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/reader_chunk.dart';

void showChapterListDrawer({
  required BuildContext context,
  required List<ChapterInfo> chapters,
  required int currentChapterNumber,
  required int currentRawIndex,
  required void Function(int chapterNumber) onChapterSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.page,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
    ),
    builder: (_) => _ChapterListContent(
      chapters: chapters,
      currentChapterNumber: currentChapterNumber,
      currentRawIndex: currentRawIndex,
      onChapterSelected: (chapterNumber) {
        Navigator.of(context).pop();
        onChapterSelected(chapterNumber);
      },
    ),
  );
}

class _ChapterListContent extends StatelessWidget {
  final List<ChapterInfo> chapters;
  final int currentChapterNumber;
  final int currentRawIndex;
  final void Function(int chapterNumber) onChapterSelected;

  const _ChapterListContent({
    required this.chapters,
    required this.currentChapterNumber,
    required this.currentRawIndex,
    required this.onChapterSelected,
  });

  bool _isChapterComplete(ChapterInfo chapter) {
    if (chapter.chapterNumber == currentChapterNumber) return false;
    final chapterEnd = chapter.startIndex + chapter.sentenceCount - 1;
    return currentRawIndex > chapterEnd;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.parchment,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CHAPTERS',
            style: AppTheme.monoLabel(fontSize: 9, letterSpacing: 3, color: AppTheme.inkLight),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, i) {
                final chapter = chapters[i];
                final isCurrent = chapter.chapterNumber == currentChapterNumber;
                final isComplete = _isChapterComplete(chapter);
                final displayTitle = stripChapterPrefix(chapter.title);

                return GestureDetector(
                  onTap: () => onChapterSelected(chapter.chapterNumber),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.tomatoLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${chapter.chapterNumber}',
                            style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent ? AppTheme.ink : AppTheme.inkMid,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Text('Reading', style: AppTheme.monoLabel(fontSize: 9, color: AppTheme.tomato))
                        else if (isComplete)
                          Text('\u{2713}', style: AppTheme.monoLabel(fontSize: 9, color: AppTheme.sage)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (chapters.length > 8)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Scroll for more chapters',
                style: GoogleFonts.playfairDisplay(fontSize: 11, color: AppTheme.inkLight),
              ),
            ),
        ],
      ),
    );
  }
}
