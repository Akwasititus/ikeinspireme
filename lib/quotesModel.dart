class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      text: map['quote'],
      author: map['author'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quote': text,
      'author': author,
    };
  }
}
