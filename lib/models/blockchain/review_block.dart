import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Model yang merepresentasikan satu blok dalam rantai ulasan (Review Blockchain Ledger).
/// Menggunakan kriptografi SHA-256 untuk menjamin integritas data ulasan anti-manipulasi.
class ReviewBlock {
  final int index; // Urutan blok (Block #0 = Genesis, #1, #2, dst.)
  final DateTime timestamp; // Waktu blok dicatat
  final String reviewId; // ID ulasan yang diikat
  final String destinationId; // ID tempat wisata
  final String userName; // Nama pengulas
  final double rating; // Rating bintang (1.0 - 5.0)
  final String comment; // Isi ulasan
  final String previousHash; // Hash dari blok sebelum ini (pengikat rantai)
  final String hash; // Hash SHA-256 unik dari isi blok ini
  final String? txHash; // Transaction Hash di Ethereum Sepolia Testnet (jika di-anchor on-chain)

  const ReviewBlock({
    required this.index,
    required this.timestamp,
    required this.reviewId,
    required this.destinationId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.previousHash,
    required this.hash,
    this.txHash,
  });

  /// Menghitung SHA-256 Hash secara deterministik dari seluruh properti blok
  static String calculateHash({
    required int index,
    required DateTime timestamp,
    required String reviewId,
    required String destinationId,
    required String userName,
    required double rating,
    required String comment,
    required String previousHash,
  }) {
    final payload = '$index|${timestamp.toIso8601String()}|$reviewId|$destinationId|$userName|$rating|$comment|$previousHash';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
  }

  /// Membuat copy objek (misal untuk simulasi manipulasi data pada demo)
  ReviewBlock copyWith({
    int? index,
    DateTime? timestamp,
    String? reviewId,
    String? destinationId,
    String? userName,
    double? rating,
    String? comment,
    String? previousHash,
    String? hash,
    String? txHash,
  }) {
    return ReviewBlock(
      index: index ?? this.index,
      timestamp: timestamp ?? this.timestamp,
      reviewId: reviewId ?? this.reviewId,
      destinationId: destinationId ?? this.destinationId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      txHash: txHash ?? this.txHash,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'timestamp': timestamp.toIso8601String(),
      'reviewId': reviewId,
      'destinationId': destinationId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'previousHash': previousHash,
      'hash': hash,
      'txHash': txHash,
    };
  }

  factory ReviewBlock.fromMap(Map<String, dynamic> map) {
    return ReviewBlock(
      index: map['index'] as int? ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      reviewId: map['reviewId'] as String? ?? '',
      destinationId: map['destinationId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Wisatawan',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      previousHash: map['previousHash'] as String? ?? '',
      hash: map['hash'] as String? ?? '',
      txHash: map['txHash'] as String?,
    );
  }
}
