class Quote {
  final String text;
  final String author;
  final String id; // Add this for unique identification
  final int likeCount; // Add global like count
  final int commentCount;
  final dynamic createdAt;

  Quote({
    required this.text,
    required this.author,
    required this.id,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] ?? '', // Make sure to store ID
      text: map['quote'],
      author: map['author'],
      createdAt: map['createdAt'],
      likeCount: map['likeCount'] ?? 0, // Add this
      commentCount: map['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote': text,
      'author': author,
      'createdAt': createdAt,
      'likeCount': likeCount,
      'commentCount': commentCount,
    };
  }
}