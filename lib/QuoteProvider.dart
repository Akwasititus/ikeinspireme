import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wiceq/quotesModel.dart';
import 'Comment.dart';

class QuoteProvider with ChangeNotifier {
  List<Quote> _quotes = [];
  List<Quote> _favorites = [];

  List<Quote> get quotes => _quotes;
  List<Quote> get favorites => _favorites;

  final CollectionReference quotesCollection =
  FirebaseFirestore.instance.collection('quotes');

  final CollectionReference commentsCollection =
  FirebaseFirestore.instance.collection('comments');

  QuoteProvider() {
    loadFavorites();
    _saveUserToken(); // ✅ Added - saves token on app start
  }

  /// Save user FCM token to Firestore ✅ KEEP THIS
  Future<void> _saveUserToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('user_tokens')
            .doc(token)
            .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': 'mobile',
        });
        print("================================================================");
        print('✅ Token saved: $token');
      }
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  // ✅ KEEP ALL COMMENT METHODS
  Future<void> addComment(
      String quoteId, String text, String authorName) async {
    try {
      final commentId = commentsCollection.doc().id;
      final newComment = Comment(
        id: commentId,
        quoteId: quoteId,
        text: text,
        authorName: authorName,
        authorId:
        'user_${DateTime.now().millisecondsSinceEpoch}', // You can replace with actual user ID
        timestamp: DateTime.now(),
      );

      // Add comment to Firestore
      await commentsCollection.doc(commentId).set(newComment.toMap());

      // Update comment count for the quote
      await quotesCollection.doc(quoteId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Refresh quotes to get updated counts
      await fetchQuotes();
      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  Stream<List<Comment>> getComments(String quoteId) {
    return commentsCollection
        .where('quoteId', isEqualTo: quoteId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  // ✅ KEEP ALL LIKE/UNLIKE FUNCTIONALITY
  Future<void> toggleLike(Quote quote) async {
    try {
      if (isFavorite(quote)) {
        // Unlike - remove from favorites and decrement global count
        _favorites.removeWhere((q) => q.id == quote.id);
        await quotesCollection.doc(quote.id).update({
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Like - add to favorites and increment global count
        _favorites.add(quote);
        await quotesCollection.doc(quote.id).update({
          'likeCount': FieldValue.increment(1),
        });
      }

      saveFavorites();
      // Refresh quotes to get updated like counts
      await fetchQuotes();
      notifyListeners();
    } catch (e) {
      print('Error toggling like: $e');
      // Rollback local changes if Firebase fails
      if (isFavorite(quote)) {
        _favorites.removeWhere((q) => q.id == quote.id);
      } else {
        _favorites.add(quote);
      }
      notifyListeners();
    }
  }

  // ✅ KEEP FETCH QUOTES WITH ID
  Future<void> fetchQuotes() async {
    try {
      final QuerySnapshot snapshot =
      await quotesCollection.orderBy('createdAt', descending: true).get();
      _quotes = snapshot.docs
          .map((doc) => Quote.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id, // Include document ID
      }))
          .toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load quotes: $e');
    }
  }

  // ✅ KEEP ADD QUOTE
  Future<void> addQuote(String text, String author) async {
    try {
      final docRef = await quotesCollection.add({
        'quote': text,
        'author': author,
        'createdAt': FieldValue.serverTimestamp(), // ✅ Added timestamp
      });
      final newQuote = Quote(text: text, author: author, id: docRef.id);
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
    _favorites
        .removeWhere((q) => q.text == quote.text && q.author == quote.author);
    saveFavorites();
    notifyListeners();
  }

  // ✅ KEEP ISFAVORITE WITH ID
  bool isFavorite(Quote quote) {
    return _favorites.any((q) => q.id == quote.id);
  }

  // ✅ KEEP SAVE FAVORITES
  void saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favoriteQuotes =
    _favorites.map((quote) => json.encode(quote.toMap())).toList();
    await prefs.setStringList('favoriteQuotes', favoriteQuotes);
  }

  // ✅ KEEP LOAD FAVORITES
  void loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favoriteQuotes = prefs.getStringList('favoriteQuotes');
    if (favoriteQuotes != null) {
      _favorites = favoriteQuotes
          .map((quote) => Quote.fromMap(json.decode(quote)))
          .toList();
    }
    notifyListeners();
  }
}
