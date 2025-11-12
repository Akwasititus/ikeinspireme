import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wiceq/quotesModel.dart';


class QuoteProvider with ChangeNotifier {
  List<Quote> _quotes = [];
  List<Quote> _favorites = [];

  List<Quote> get quotes => _quotes;
  List<Quote> get favorites => _favorites;

  final CollectionReference quotesCollection =
  FirebaseFirestore.instance.collection('quotes');

  QuoteProvider() {
    loadFavorites();
  }

  Future<void> fetchQuotes() async {
    try {
      final QuerySnapshot snapshot = await quotesCollection
          .orderBy('createdAt', descending: true)
          .get();
      _quotes = snapshot.docs
          .map((doc) => Quote.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load quotes: $e');
    }
  }

  Future<void> addQuote(String text, String author) async {
    try {
      final docRef = await quotesCollection.add({
        'quote': text,
        'author': author,
      });
      final newQuote = Quote(text: text, author: author);
      _quotes.add(newQuote);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add quote: $e');
    }
  }



  void addFavorite(Quote quote) {
    _favorites.add(quote);
    saveFavorites();
    notifyListeners();
  }

  void removeFavorite(Quote quote) {
    _favorites.removeWhere((q) => q.text == quote.text && q.author == quote.author);
    saveFavorites();
    notifyListeners();
  }

  bool isFavorite(Quote quote) {
    return _favorites.any((q) => q.text == quote.text && q.author == quote.author);
  }

  void saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoriteQuotes = _favorites.map((quote) => json.encode(quote.toMap())).toList();
    await prefs.setStringList('favoriteQuotes', favoriteQuotes);
  }

  void loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favoriteQuotes = prefs.getStringList('favoriteQuotes');
    if (favoriteQuotes != null) {
      _favorites = favoriteQuotes.map((quote) => Quote.fromMap(json.decode(quote))).toList();
    }
    notifyListeners();
  }
}

