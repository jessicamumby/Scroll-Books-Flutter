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
