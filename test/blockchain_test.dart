import 'package:flutter_test/flutter_test.dart';
import 'package:projek_akhir/models/destination_review.dart';
import 'package:projek_akhir/services/review_blockchain_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReviewBlockchainService Tests', () {
    test('Initializes blockchain with Genesis Block', () async {
      final blockchain = ReviewBlockchainService();
      await blockchain.init();

      expect(blockchain.isInitialized, true);
      expect(blockchain.totalBlocks, greaterThanOrEqualTo(1));
      expect(blockchain.chain.first.index, 0);
      expect(blockchain.chain.first.userName, 'Sistem Konsensus BandungHub');
    });

    test('Adds new review block and links hashes cryptographically', () async {
      final blockchain = ReviewBlockchainService();
      await blockchain.init();

      final initialCount = blockchain.totalBlocks;
      final review = DestinationReview(
        id: 'rev_test_01',
        destinationId: 'dest_01',
        userName: 'Budi Santoso',
        rating: 5.0,
        comment: 'Tempatnya asri dan sangat terawat!',
        createdAt: DateTime.now(),
      );

      final newBlock = await blockchain.addReviewBlock(review);

      expect(blockchain.totalBlocks, initialCount + 1);
      expect(newBlock.reviewId, 'rev_test_01');
      expect(newBlock.previousHash, blockchain.chain[newBlock.index - 1].hash);

      // Verify audit passes
      final audit = blockchain.auditChain();
      expect(audit['isValid'], true);
    });

    test('Validates chain integrity and block verification', () async {
      final blockchain = ReviewBlockchainService();
      await blockchain.init();

      final review = DestinationReview(
        id: 'rev_test_02',
        destinationId: 'dest_02',
        userName: 'Siti Rahma',
        rating: 4.5,
        comment: 'Pemandangannya indah sekali.',
        createdAt: DateTime.now(),
      );
      final block = await blockchain.addReviewBlock(review);

      final audit = blockchain.auditChain();
      expect(audit['isValid'], true);
      expect(audit['brokenBlockIndex'], isNull);
      expect(audit['totalVerifiedBlocks'], blockchain.totalBlocks);
      expect(block.hash.isNotEmpty, true);
    });
  });
}
