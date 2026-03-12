class ReaderChunk {
  final String text;
  final String type;
  final int chapter;

  const ReaderChunk({
    required this.text,
    required this.type,
    required this.chapter,
  });

  bool get isChapterHeader => type == 'chapter_header';
  bool get isSentence => type == 'sentence';
}

String stripChapterPrefix(String headerText) {
  final dotSpace = headerText.indexOf('. ');
  if (dotSpace == -1) return headerText;
  return headerText.substring(dotSpace + 2);
}

class ChapterInfo {
  final int chapterNumber;
  final String title;
  final int startIndex;
  final int sentenceCount;

  const ChapterInfo({
    required this.chapterNumber,
    required this.title,
    required this.startIndex,
    required this.sentenceCount,
  });
}

List<ChapterInfo> buildChapterInfoList(List<ReaderChunk> chunks) {
  final chapters = <ChapterInfo>[];
  String? currentTitle;
  int? currentChapterNumber;
  int currentStartIndex = 0;
  int currentSentenceCount = 0;

  for (int i = 0; i < chunks.length; i++) {
    final chunk = chunks[i];
    if (chunk.isChapterHeader) {
      if (currentTitle != null) {
        chapters.add(ChapterInfo(
          chapterNumber: currentChapterNumber!,
          title: currentTitle,
          startIndex: currentStartIndex,
          sentenceCount: currentSentenceCount,
        ));
      }
      currentTitle = chunk.text;
      currentChapterNumber = chunk.chapter;
      currentStartIndex = i + 1;
      currentSentenceCount = 0;
    } else if (chunk.isSentence && currentTitle != null) {
      if (currentSentenceCount == 0) {
        currentStartIndex = i;
      }
      currentSentenceCount++;
    }
  }

  if (currentTitle != null) {
    chapters.add(ChapterInfo(
      chapterNumber: currentChapterNumber!,
      title: currentTitle,
      startIndex: currentStartIndex,
      sentenceCount: currentSentenceCount,
    ));
  }

  return chapters;
}

sealed class DisplayItem {
  const DisplayItem();
}

class SentenceItem extends DisplayItem {
  final String text;
  final int rawIndex;
  final int chapterNumber;
  final String? chapterTitle;
  final int sentenceOrdinal;

  const SentenceItem({
    required this.text,
    required this.rawIndex,
    required this.chapterNumber,
    this.chapterTitle,
    required this.sentenceOrdinal,
  });

  bool get isChapterOpener => chapterTitle != null;
}

class ChapterCompleteItem extends DisplayItem {
  final int completedChapterNumber;
  final String completedChapterTitle;
  final int passagesInChapter;
  final int totalChapters;
  final int sentencesReadSoFar;
  final int totalSentences;

  const ChapterCompleteItem({
    required this.completedChapterNumber,
    required this.completedChapterTitle,
    required this.passagesInChapter,
    required this.totalChapters,
    required this.sentencesReadSoFar,
    required this.totalSentences,
  });

  int get bookProgressPercent =>
      totalSentences > 0 ? (sentencesReadSoFar / totalSentences * 100).round() : 0;
}

List<DisplayItem> buildDisplayList(List<ReaderChunk> chunks, List<ChapterInfo> chapters) {
  // Legacy mode: no chapters — return flat sentence list
  if (chapters.isEmpty) {
    int ordinal = 0;
    return chunks.asMap().entries.where((e) => e.value.isSentence).map((e) {
      ordinal++;
      return SentenceItem(
        text: e.value.text,
        rawIndex: e.key,
        chapterNumber: 0,
        sentenceOrdinal: ordinal,
      );
    }).toList();
  }

  final totalSentences = chunks.where((c) => c.isSentence).length;
  final totalChapters = chapters.length;
  final display = <DisplayItem>[];
  int sentenceOrdinal = 0;
  int cumulativeSentences = 0;

  for (int ci = 0; ci < chapters.length; ci++) {
    final chapter = chapters[ci];
    final isLast = ci == chapters.length - 1;
    final strippedTitle = stripChapterPrefix(chapter.title);
    bool isFirstSentence = true;

    for (int i = chapter.startIndex;
         i < chunks.length && chunks[i].chapter == chapter.chapterNumber;
         i++) {
      final chunk = chunks[i];
      if (chunk.isSentence) {
        sentenceOrdinal++;
        display.add(SentenceItem(
          text: chunk.text,
          rawIndex: i,
          chapterNumber: chapter.chapterNumber,
          chapterTitle: isFirstSentence ? strippedTitle : null,
          sentenceOrdinal: sentenceOrdinal,
        ));
        isFirstSentence = false;
      }
    }

    cumulativeSentences += chapter.sentenceCount;

    if (!isLast) {
      display.add(ChapterCompleteItem(
        completedChapterNumber: chapter.chapterNumber,
        completedChapterTitle: strippedTitle,
        passagesInChapter: chapter.sentenceCount,
        totalChapters: totalChapters,
        sentencesReadSoFar: cumulativeSentences,
        totalSentences: totalSentences,
      ));
    }
  }

  return display;
}

int displayIndexForRawIndex(List<DisplayItem> displayList, int rawIndex) {
  if (displayList.isEmpty) return 0;

  for (int i = 0; i < displayList.length; i++) {
    final item = displayList[i];
    if (item is SentenceItem && item.rawIndex == rawIndex) return i;
  }

  for (int i = 0; i < displayList.length; i++) {
    final item = displayList[i];
    if (item is SentenceItem && item.rawIndex >= rawIndex) return i;
  }

  for (int i = displayList.length - 1; i >= 0; i--) {
    if (displayList[i] is SentenceItem) return i;
  }

  return 0;
}
