import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/blockchain/review_block.dart';
import '../models/destination_review.dart';

/// Service inti pengelola Buku Besar Blockchain untuk Ulasan Destinasi (Review Blockchain Ledger).
/// Mengontrol pembuatan blok, persistensi data, validasi rantai (audit), dan simulasi demo.
class ReviewBlockchainService extends ChangeNotifier {
  static final ReviewBlockchainService _instance =
      ReviewBlockchainService._internal();
  factory ReviewBlockchainService() => _instance;
  ReviewBlockchainService._internal();

  static const String _storageKey = 'bandunghub_review_blockchain_v1';
  static const String _genesisPreviousHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  final List<ReviewBlock> _chain = [];
  bool _isInitialized = false;

  List<ReviewBlock> get chain => List.unmodifiable(_chain);
  int get totalBlocks => _chain.length;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi blockchain & load dari penyimpanan lokal
  Future<void> init() async {
    if (_isInitialized) return;

    await _loadFromStorage();
    if (_chain.isEmpty) {
      _createGenesisBlock();
      await _saveToStorage();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Membuat Blok #0 (Genesis Block) sebagai akar kepercayaan rantai
  void _createGenesisBlock() {
    final genesisTime = DateTime(2026, 1, 1, 0, 0, 0);
    final genesisHash = ReviewBlock.calculateHash(
      index: 0,
      timestamp: genesisTime,
      reviewId: 'genesis_review',
      destinationId: 'bandung_system',
      userName: 'Sistem Konsensus BandungHub',
      rating: 5.0,
      comment:
          'Genesis Block: Rantai Kepercayaan Ulasan Wisata Bandung Resmi Diinisialisasi.',
      previousHash: _genesisPreviousHash,
    );

    _chain.add(
      ReviewBlock(
        index: 0,
        timestamp: genesisTime,
        reviewId: 'genesis_review',
        destinationId: 'bandung_system',
        userName: 'Sistem Konsensus BandungHub',
        rating: 5.0,
        comment:
            'Genesis Block: Rantai Kepercayaan Ulasan Wisata Bandung Resmi Diinisialisasi.',
        previousHash: _genesisPreviousHash,
        hash: genesisHash,
      ),
    );
  }

  /// Menambahkan blok baru ke rantai berdasarkan ulasan yang dikirim pengguna
  Future<ReviewBlock> addReviewBlock(DestinationReview review) async {
    // Pastikan service sudah diinisialisasi
    if (!_isInitialized) {
      await init();
    }

    final previousBlock = _chain.last;
    final newIndex = _chain.length;
    final timestamp = review.createdAt;

    final newHash = ReviewBlock.calculateHash(
      index: newIndex,
      timestamp: timestamp,
      reviewId: review.id,
      destinationId: review.destinationId,
      userName: review.userName,
      rating: review.rating,
      comment: review.comment,
      previousHash: previousBlock.hash,
    );

    final newBlock = ReviewBlock(
      index: newIndex,
      timestamp: timestamp,
      reviewId: review.id,
      destinationId: review.destinationId,
      userName: review.userName,
      rating: review.rating,
      comment: review.comment,
      previousHash: previousBlock.hash,
      hash: newHash,
    );

    _chain.add(newBlock);
    notifyListeners();
    await _saveToStorage();

    debugPrint(
      '⛓️ [Blockchain] Blok #${newBlock.index} dicetak untuk ulasan "${review.id}". Hash: ${newBlock.hash.substring(0, 16)}...',
    );

    return newBlock;
  }

  /// Sinkronisasi awal: Cetak blok untuk ulasan default jika belum tercatat di blockchain
  Future<void> syncWithExistingReviews(List<DestinationReview> reviews) async {
    if (!_isInitialized) await init();

    bool hasNewBlock = false;
    for (final rev in reviews) {
      final alreadyExists = _chain.any((b) => b.reviewId == rev.id);
      if (!alreadyExists) {
        final previousBlock = _chain.last;
        final newIndex = _chain.length;
        final newHash = ReviewBlock.calculateHash(
          index: newIndex,
          timestamp: rev.createdAt,
          reviewId: rev.id,
          destinationId: rev.destinationId,
          userName: rev.userName,
          rating: rev.rating,
          comment: rev.comment,
          previousHash: previousBlock.hash,
        );

        _chain.add(
          ReviewBlock(
            index: newIndex,
            timestamp: rev.createdAt,
            reviewId: rev.id,
            destinationId: rev.destinationId,
            userName: rev.userName,
            rating: rev.rating,
            comment: rev.comment,
            previousHash: previousBlock.hash,
            hash: newHash,
          ),
        );
        hasNewBlock = true;
      }
    }

    if (hasNewBlock) {
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Mengambil blok berdasarkan ID ulasan
  ReviewBlock? getBlockForReview(String reviewId) {
    try {
      return _chain.firstWhere((b) => b.reviewId == reviewId);
    } catch (_) {
      return null;
    }
  }

  /// Memeriksa validitas dan integritas seluruh rantai (Audit Kriptografi)
  Map<String, dynamic> auditChain() {
    if (_chain.isEmpty) {
      return {
        'isValid': false,
        'errorMessage': 'Rantai kosong (belum ada Genesis Block).',
        'brokenBlockIndex': null,
      };
    }

    // 1. Validasi Genesis Block
    final genesis = _chain.first;
    if (genesis.index != 0 || genesis.previousHash != _genesisPreviousHash) {
      return {
        'isValid': false,
        'errorMessage': 'Genesis Block tidak valid atau telah dimodifikasi.',
        'brokenBlockIndex': 0,
      };
    }

    // 2. Validasi setiap blok berantai
    for (int i = 1; i < _chain.length; i++) {
      final current = _chain[i];
      final previous = _chain[i - 1];

      // Periksa keterikatan hash blok sebelumnya
      if (current.previousHash != previous.hash) {
        return {
          'isValid': false,
          'errorMessage':
              'Rantai terputus pada Blok #${current.index}: Previous Hash tidak cocok dengan Hash Blok #${previous.index}!',
          'brokenBlockIndex': current.index,
        };
      }

      // Periksa integritas isi blok saat ini (re-calculate hash)
      final recalculatedHash = ReviewBlock.calculateHash(
        index: current.index,
        timestamp: current.timestamp,
        reviewId: current.reviewId,
        destinationId: current.destinationId,
        userName: current.userName,
        rating: current.rating,
        comment: current.comment,
        previousHash: current.previousHash,
      );

      if (current.hash != recalculatedHash) {
        return {
          'isValid': false,
          'errorMessage':
              'Data dimanipulasi pada Blok #${current.index}: Isi data (rating/komentar) tidak sesuai dengan Hash terdaftar!',
          'brokenBlockIndex': current.index,
        };
      }
    }

    return {
      'isValid': true,
      'errorMessage': null,
      'brokenBlockIndex': null,
      'totalVerifiedBlocks': _chain.length,
    };
  }

  /// Fitur Simulasi Manipulasi Data (Khusus Pembuktian Demo & Presentasi)
  /// Mengubah data blok secara paksa tanpa memperbarui hash untuk membuktikan deteksi kecurangan
  void simulateTamper(int blockIndex, {String fakeComment = '[MANIPULASI] Ulasan ini telah diubah secara ilegal!', double fakeRating = 5.0}) {
    if (blockIndex <= 0 || blockIndex >= _chain.length) return;

    final target = _chain[blockIndex];
    _chain[blockIndex] = target.copyWith(
      comment: fakeComment,
      rating: fakeRating,
    );
    notifyListeners();
  }

  /// Mengembalikan rantai ke data asli dari penyimpanan lokal (Reset setelah simulasi)
  Future<void> restoreChain() async {
    await _loadFromStorage();
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _chain.clear();
        for (final item in decoded) {
          _chain.add(ReviewBlock.fromMap(Map<String, dynamic>.from(item as Map)));
        }
      }
    } catch (e) {
      debugPrint('Error loading ReviewBlockchain: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = _chain.map((b) => b.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(mapped));
    } catch (e) {
      debugPrint('Error saving ReviewBlockchain: $e');
    }
  }
}
