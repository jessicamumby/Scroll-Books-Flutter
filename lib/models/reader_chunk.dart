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
