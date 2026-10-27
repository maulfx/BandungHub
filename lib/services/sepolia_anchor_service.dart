import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

/// Service untuk melakukan anchoring (penambatan) hash blok ulasan BandungHub
/// ke blockchain publik Ethereum Sepolia Testnet via Alchemy RPC.
class SepoliaAnchorService {
  static final SepoliaAnchorService _instance = SepoliaAnchorService._internal();
  factory SepoliaAnchorService() => _instance;
  SepoliaAnchorService._internal();

  // Konfigurasi RPC Sepolia dan Wallet
  static const String rpcUrl =
      'https://eth-sepolia.g.alchemy.com/v2/alch_MdsjpCu5lPcA4-vyOBc0D';
  static const String privateKeyHex =
      '6f2c10d9840fc183377bed59b3eb3c8ff4f4e998c7f46f8f4a71d5b7a4885f2c';
  static const int chainId = 11155111; // Sepolia Chain ID

  http.Client? _httpClient;
  Web3Client? _ethClient;

  Web3Client get client {
    _httpClient ??= http.Client();
    _ethClient ??= Web3Client(rpcUrl, _httpClient!);
    return _ethClient!;
  }

  /// Mendapatkan alamat wallet yang diturunkan dari private key
  String get walletAddress {
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      return credentials.address.toString();
    } catch (_) {
      return '';
    }
  }

  /// Memeriksa saldo Sepolia ETH saat ini
  Future<double> getBalanceInEther() async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final balance = await client.getBalance(credentials.address);
      return balance.getInWei.toDouble() / 1e18;
    } catch (e) {
      debugPrint('⚠️ [Sepolia] Gagal memeriksa saldo: $e');
      return 0.0;
    }
  }

  /// Mengirim transaksi 0 ETH ke Sepolia dengan hash ulasan di calldata (data payload)
  /// Mengembalikan txHash (Transaction Hash) yang bisa dicari di https://sepolia.etherscan.io/tx/[txHash]
  Future<String?> anchorBlockHash({
    required int blockIndex,
    required String blockHash,
    required String reviewId,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final myAddress = credentials.address;

      // Cek saldo dulu sebelum mengirim transaksi
      final balance = await client.getBalance(myAddress);
      if (balance.getInWei == BigInt.zero) {
        debugPrint(
          '⚠️ [Sepolia] Saldo wallet 0 ETH. Melewati anchoring on-chain untuk Blok #$blockIndex.',
        );
        return null;
      }

      // Format payload calldata: "BANDUNGHUB:BLOCK:index:hash"
      final payloadString = 'BANDUNGHUB:BLOCK:$blockIndex:$blockHash';
      final payloadData = Uint8List.fromList(utf8.encode(payloadString));

      // Kirim transaksi 0 ETH ke diri sendiri dengan data ulasan
      final txHash = await client.sendTransaction(
        credentials,
        Transaction(
          to: myAddress,
          data: payloadData,
        ),
        chainId: chainId,
      );

      debugPrint('✅ [Sepolia] Berhasil di-anchor ke Sepolia! TxHash: $txHash');
      return txHash;
    } catch (e) {
      debugPrint('⚠️ [Sepolia] Gagal anchor blok #$blockIndex ke Sepolia: $e');
      return null;
    }
  }

  /// Helper untuk generate link Etherscan Sepolia
  static String getEtherscanUrl(String txHash) {
    return 'https://sepolia.etherscan.io/tx/$txHash';
  }

  void dispose() {
    _ethClient?.dispose();
    _httpClient?.close();
    _ethClient = null;
    _httpClient = null;
  }
}
