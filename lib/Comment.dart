import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Comment {
  final String id;
  final String quoteId;
  final String text;
  final String authorName;
  final String authorId;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.quoteId,
    required this.text,
    required this.authorName,
    required this.authorId,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      quoteId: map['quoteId'],
      text: map['text'],
      authorName: map['authorName'],
      authorId: map['authorId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quoteId': quoteId,
      'text': text,
      'authorName': authorName,
      'authorId': authorId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}