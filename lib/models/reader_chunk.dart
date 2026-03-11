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
