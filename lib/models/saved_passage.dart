class SavedPassage {
  final String id;
  final String bookId;
  final int chunkIndex;
  final String passageText;
  final DateTime savedAt;

  const SavedPassage({
    required this.id,
    required this.bookId,
    required this.chunkIndex,
    required this.passageText,
    required this.savedAt,
  });

  factory SavedPassage.fromJson(Map<String, dynamic> json) => SavedPassage(
        id: json['id'] as String,
        bookId: json['book_id'] as String,
        chunkIndex: json['chunk_index'] as int,
        passageText: json['passage_text'] as String,
        savedAt: DateTime.parse(json['saved_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'chunk_index': chunkIndex,
        'passage_text': passageText,
      };
}
