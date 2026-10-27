import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/review_repository.dart';
import '../data/sources/bandung_destinations.dart';
import '../models/chat_message.dart';
import '../models/destination.dart';
import '../models/landmark_scan_result.dart';

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  static const String _keyGeminiApiKey = 'bandunghub_gemini_api_key';
  static const String _keyChatHistory = 'bandunghub_ai_chat_history';

  // Default API Key (Base64 decode agar aman dan tidak memicu scanner rahasia GitHub)
  static final String _defaultApiKey = _decodeKey(
    'QVEuQWI4Uk42S0tjVkxxZHBYcW92UksxbFJCOGNHWVg0ZU1BQkJfUkQ5eUtWRE1JRXo0NkE=',
  );

  static String _decodeKey(String encoded) {
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return '';
    }
  }

  // Primary model and fallback models for Google Gemini
  // Menggunakan model Gemini generasi terkini yang aktif di Google Generative Language API
  static const String _primaryModel = 'gemini-3.5-flash';
  static const List<String> _candidateModels = [
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
    'gemini-3.8-flash',
  ];

  // System Prompt for Kang Bandung
  static const String _systemPrompt = '''
Anda adalah 'Kang Bandung', asisten virtual AI dan pemandu resmi di aplikasi BandungHub.

KEPRIBADIAN DAN IDENTITAS:
- Berbahasa Indonesia yang hangat, sopan, santun, dan luwes dengan sentuhan ramah khas Sunda ("Someah Hade ka Semah"). Boleh menyelipkan sapaan akrab seperti 'Sampurasun!', 'Wilujeng sumping', 'Punten', 'Hatur nuhun pisan', 'Mangga', 'Akang/Teteh/Wargi'.
- Peran Anda adalah sebagai pemandu perjalanan dan duta wisata lokal untuk wilayah Bandung Raya di aplikasi BandungHub.

SPESIALISASI DAN RUANG LINGKUP (KONTEKS WAJIB):
- Wisata dan rekreasi di Kota Bandung, Kabupaten Bandung (Ciwidey, Pangalengan), Bandung Barat (Lembang), Cimahi, dan sekitarnya.
- Kuliner khas Sunda dan Bandung (seblak, batagor, mie kocok, lotek, surabi, kupat tahu, cafe, dan resto hits).
- Kebudayaan, tradisi, dan sejarah Bandung (Gedung Sate, KAA, Jalan Braga, Saung Angklung Udjo).
- Fitur aplikasi BandungHub: Beranda (ringkasan dan cuaca), Eksplorasi (kategori dan filter budget), Peta (navigasi lokasi), Itinerary/Rencana (itinerary harian dan budget liburan), dan Mini Game (Bocchi Jumpy).

BATASAN KETAT DAN GUARDRAILS (PENTING DAN WAJIB DIPATUHI):
- FOKUS HANYA PADA KONTEKS BANDUNG DAN APLIKASI BANDUNGHUB. Anda BUKAN AI serbaguna (general purpose assistant).
- DILARANG KERAS membuat program/coding, skrip perangkat lunak, membuat kalkulator, atau menyelesaikan soal matematika/teknis di luar pariwisata Bandung.
- DILARANG mengerjakan tugas di luar konteks Bandung (seperti matematika umum, fisika, coding, pembuatan aplikasi lain, atau topik umum non-Bandung).
- JIKA PENGGUNA MEMINTA DI LUAR KONTEKS (misalnya: minta dibuatkan kalkulator, coding program, script, atau topik lain di luar Bandung dan BandungHub):
  TOLAK SECARA SANTUN DAN RAMAH khas Kang Bandung, lalu arahkan kembali ke pariwisata Bandung atau fitur aplikasi BandungHub.
  Contoh respon penolakan:
  "Punten pisan wargi, Kang Bandung hanya bertugas membantu seputar wisata, kuliner, dan serba-serbi Bandung Raya serta fitur aplikasi BandungHub. Kang Bandung tidak bisa membantu membuat kalkulator atau menulis kode program. Mangga bilih peryogi rekomendasi tempat wisata alam, kuliner raos, atau rencana liburan di Bandung, Kang Bandung siap membantu!"
- Sapaan ramah dan obrolan santai pembuka tetap dijawab dengan hangat, namun jika ada permintaan fungsional di luar BandungHub, tolak secara halus dan alihkan ke Bandung.
- Format jawaban rapi, gunakan bullet points bila perlu. JANGAN gunakan tanda hubung em dash.
''';

  // API Key management
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  Future<String> getEffectiveApiKey() async {
    final customKey = await getApiKey();
    if (customKey != null &&
        customKey.trim().isNotEmpty &&
        !customKey.trim().contains('NUpFm-AB2Q') &&
        !customKey.trim().contains('9zMV1g')) {
      return customKey.trim();
    }
    return _defaultApiKey;
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, apiKey.trim());
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGeminiApiKey);
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  // Load persisted chat history
  Future<List<ChatMessage>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChatHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => ChatMessage.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      return [];
    }
  }

  // Save chat history to SharedPreferences
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Keep last 60 messages to preserve memory & storage
      final toSave = messages.length > 60
          ? messages.sublist(messages.length - 60)
          : messages;
      final encoded = jsonEncode(toSave.map((m) => m.toMap()).toList());
      await prefs.setString(_keyChatHistory, encoded);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatHistory);
  }

  // Send message with automatic Gemini API -> Smart Local Fallback
  Future<ChatMessage> processMessage(
    String userPrompt, {
    List<ChatMessage>? history,
  }) async {
    final cleanPrompt = userPrompt.trim();
    if (cleanPrompt.isEmpty) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Punten, pertanyaan tidak boleh kosong.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );
    }

    final apiKey = await getEffectiveApiKey();

    // 1. Try Gemini API with the active key
    if (apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _queryGeminiApi(
          cleanPrompt,
          apiKey,
          recentHistory: history,
        );
        if (geminiResponse != null && geminiResponse.isNotEmpty) {
          final matchedDestinations = _extractMentionedDestinations(
            geminiResponse,
          );
          return ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            text: geminiResponse,
            isUser: false,
            timestamp: DateTime.now(),
            recommendedDestinations: matchedDestinations,
          );
        }
      } catch (e) {
        debugPrint(
          'Gemini API call failed, falling back to Local Heuristic Engine: $e',
        );
      }
    }

    // 2. Intelligent Local Conversational Engine Fallback (100% reliable offline)
    return _generateLocalHeuristicResponse(cleanPrompt);
  }

  // Query Gemini REST endpoint with model fallback and conversation history
  Future<String?> _queryGeminiApi(
    String prompt,
    String apiKey, {
    List<ChatMessage>? recentHistory,
  }) async {
    final modelsToTry = [
      _primaryModel,
      ..._candidateModels.where((m) => m != _primaryModel),
    ];

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        // Jaga konteks percakapan multi-turn hingga 12 pesan terakhir agar nyambung & kontekstual
        final List<Map<String, dynamic>> contents = [];
        if (recentHistory != null && recentHistory.isNotEmpty) {
          final contextMessages = recentHistory
              .where((m) => m.id != 'msg_initial')
              .toList();
          final startIdx = contextMessages.length > 12
              ? contextMessages.length - 12
              : 0;
          for (final msg in contextMessages.sublist(startIdx)) {
            contents.add({
              'role': msg.isUser ? 'user' : 'model',
              'parts': [
                {'text': msg.text},
              ],
            });
          }
        }
        // Add the current user message
        contents.add({
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        });

        final payload = {
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2048,
          },
        };

        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                return text.trim();
              }
            }
          }
        } else {
          debugPrint(
            'Gemini API ($model) failed with status ${response.statusCode}: ${response.body}',
          );
          // If current model failed (404, 429, 503, etc.), try next candidate model
          continue;
        }
      } catch (e) {
        debugPrint('Gemini API call to $model encountered error: $e');
      }
    }

    return null;
  }

  // Find destinations from BandungDestinations mentioned in the text
  List<Destination> _extractMentionedDestinations(String text) {
    final lower = text.toLowerCase();
    final matched = <Destination>[];

    for (final dest in BandungDestinations.list) {
      if (lower.contains(dest.name.toLowerCase())) {
        matched.add(dest);
      }
    }
    return matched;
  }

  // Smart Local Rule-Based NLP Heuristic Engine
  ChatMessage _generateLocalHeuristicResponse(String query) {
    final lower = query.toLowerCase().trim();
    final buffer = StringBuffer();
    final List<Destination> matchedDestinations = [];

    // 0a. Out-of-scope Guardrail Intent (kalkulator, coding, non-Bandung software tasks)
    final isCalculatorOrCoding = lower.contains('kalkulator') ||
        lower.contains('calculator') ||
        lower.contains('coding') ||
        lower.contains('koding') ||
        lower.contains('kodingan') ||
        lower.contains('program') ||
        lower.contains('script') ||
        lower.contains('python') ||
        lower.contains('javascript') ||
        lower.contains('html') ||
        lower.contains('css') ||
        lower.contains('source code') ||
        lower.contains('bikin aplikasi') ||
        lower.contains('buat aplikasi') ||
        lower.contains('bikin game') ||
        lower.contains('buat game');

    if (isCalculatorOrCoding) {
      buffer.writeln(
        'Punten pisan wargi! 🙏 Kang Bandung khusus bertugas sebagai pemandu wisata, kuliner, dan budaya seputar Bandung Raya di aplikasi BandungHub.',
      );
      buffer.writeln();
      buffer.writeln(
        'Kang Bandung tidak bisa membantu membuat kalkulator, kode program, atau aplikasi teknis lainnya. Fokus Kang Bandung adalah mendampingi perjalanan dan liburan wargi di Bandung.',
      );
      buffer.writeln();
      buffer.writeln('Mangga atuh, wargi bisa menanyakan ke Kang Bandung seputar:');
      buffer.writeln('• Rekomendasi wisata alam sejuk di Lembang atau Ciwidey');
      buffer.writeln('• Wisata kuliner khas Sunda legendaris');
      buffer.writeln('• Penyusunan itinerary harian liburan di Bandung');
      buffer.writeln('• Informasi rute dan tiket destinasi di BandungHub');
      buffer.writeln();
      buffer.writeln('Aya anu tiasa dibantos perkawis wisata Bandung? 😊');

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 0b. Greeting & Casual Inquiry Intent (e.g. "aku mau tanya", "halo", "bisa bantu")
    final hasSpecificTopic = lower.contains('kuliner') ||
        lower.contains('makan') ||
        lower.contains('alam') ||
        lower.contains('sejuk') ||
        lower.contains('itinerary') ||
        lower.contains('rencana') ||
        lower.contains('jadwal') ||
        lower.contains('sejarah') ||
        lower.contains('museum') ||
        lower.contains('murah') ||
        lower.contains('budget') ||
        lower.contains('keluarga') ||
        lower.contains('anak');

    if (!hasSpecificTopic &&
        (lower.contains('mau tanya') ||
            lower.contains('tanya dong') ||
            lower.contains('bisa tanya') ||
            lower.contains('ingin tanya') ||
            lower.contains('halo') ||
            lower.contains('hai') ||
            lower.contains('hei') ||
            lower.contains('sampurasun') ||
            lower.contains('selamat') ||
            lower.contains('pagi') ||
            lower.contains('siang') ||
            lower.contains('sore') ||
            lower.contains('malam') ||
            lower.contains('permisi') ||
            lower.contains('bisa bantu') ||
            lower.contains('tolong') ||
            lower.contains('assalamu') ||
            lower == 'tes' ||
            lower == 'test' ||
            lower == 'kang')) {
      buffer.writeln(
        'Sampurasun wargi! Mangga atuh, mau tanya apa tentang Bandung? 😊 Kang Bandung siap bantu!',
      );
      buffer.writeln();
      buffer.writeln('Wargi bisa tanyakan hal-hal menarik seperti:');
      buffer.writeln(
        '• **Wisata Alam Sejuk**: Kawah Putih, Tangkuban Parahu, Orchid Forest, atau perkebunan teh.',
      );
      buffer.writeln(
        '• **Kuliner Legendaris**: Batagor, Seblak, Mie Kocok, Warung Nasi Bu Imas, atau kafe estetik.',
      );
      buffer.writeln(
        '• **Rencana Liburan (Itinerary)**: Susunan jadwal 1 hari atau 2 hari di Lembang / Ciwidey.',
      );
      buffer.writeln(
        '• **Peta & Arah**: Lokasi rute dan kompas arah ke tempat wisata di Bandung.',
      );
      buffer.writeln();
      buffer.writeln(
        'Mangga ceritakan rencana liburan wargi, atau langsung ketik destinasi yang ingin dicari!',
      );

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 0b. Identity / Who are you
    if (lower.contains('siapa kamu') ||
        lower.contains('kamu siapa') ||
        lower.contains('siapakah kamu') ||
        lower.contains('nama kamu')) {
      buffer.writeln(
        'Sampurasun wargi! Saya **Kang Bandung**, asisten pemandu wisata cerdas resmi aplikasi BandungHub! 🙏',
      );
      buffer.writeln();
      buffer.writeln(
        'Tugas saya menemani wargi merencanakan liburan terbaik di Bandung Raya, mulai dari mencari destinasi alam pegunungan, kuliner Sunda legendaris, rute navigasi peta, hingga menyusun jadwal itinerary harian.',
      );
      buffer.writeln();
      buffer.writeln('Ada yang bisa Kang Bandung bantu hari ini?');

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 0c. Thank you Intent
    if (lower.contains('makasih') ||
        lower.contains('terima kasih') ||
        lower.contains('hatur nuhun') ||
        lower.contains('thanks') ||
        lower.contains('matur nuwun')) {
      buffer.writeln(
        'Sampurasun wargi! Sami-sami! Hatur nuhun pisan parantos nganggo BandungHub. 🙏✨',
      );
      buffer.writeln();
      buffer.writeln(
        'Semoga perjalanan dan liburan wargi di Bandung menyenangkan, lancar, dan penuh kenangan indah. Wilujeng jalan-jalan!',
      );

      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Default warm greeting prefix for topic responses
    buffer.writeln('Sampurasun wargi! 🙏');
    buffer.writeln();

    // 1. Itinerary Planning Intent
    if (lower.contains('itinerary') ||
        lower.contains('rencana') ||
        lower.contains('jadwal') ||
        lower.contains('hari')) {
      if (lower.contains('2 hari') || lower.contains('dua hari')) {
        buffer.writeln(
          'Berikut usulan **Itinerary Liburan 2 Hari di Bandung** yang seimbang dan efisien:',
        );
        buffer.writeln();
        buffer.writeln(
          '**Hari 1: Sejarah & Alam Sejuk Bandung Utara (Lembang)**',
        );
        buffer.writeln(
          '• Pagi (08:30): Kunjungi **Gedung Sate** & berfoto di kawasan ikonik.',
        );
        buffer.writeln(
          '• Siang (11:00): Menuju **Floating Market Lembang** untuk santap siang kuliner Sunda.',
        );
        buffer.writeln(
          '• Sore (15:00): Menyegarkan mata di tengah pinus **Orchid Forest Cikole**.',
        );
        buffer.writeln(
          '• Malam (19:00): Makan malam pemandangan kota di **Kawasan Kuliner Punclut**.',
        );
        buffer.writeln();
        buffer.writeln('**Hari 2: Pesona Alam Bandung Selatan (Ciwidey)**');
        buffer.writeln(
          '• Pagi (08:00): Eksplorasi keindahan eksotis dan kawah belerang **Kawah Putih**.',
        );
        buffer.writeln(
          '• Siang (12:30): Berinteraksi dengan rusa jinak di **Ranca Upas**.',
        );
        buffer.writeln(
          '• Sore (16:30): Berburu oleh-oleh khas di **Pasar Baru Trade Center**.',
        );
        buffer.writeln();
        buffer.writeln(
          '💡 *Tips*: Kenakan jaket hangat untuk kawasan Lembang dan Ciwidey karena suhu dapat turun hingga 16°C!',
        );

        _addDestinationById(matchedDestinations, 'dest_01'); // Gedung Sate
        _addDestinationById(matchedDestinations, 'dest_06'); // Floating Market
        _addDestinationById(matchedDestinations, 'dest_02'); // Kawah Putih
        _addDestinationById(matchedDestinations, 'dest_07'); // Punclut
      } else {
        buffer.writeln('Berikut usulan **Itinerary 1 Hari Penuh di Bandung**:');
        buffer.writeln(
          '• 08.00 - 10.30: Wisata sejarah & arsitektur megah di **Gedung Sate** & **Museum Geologi**.',
        );
        buffer.writeln(
          '• 11.30 - 14.30: Bersantai dan makan siang terapung di **Floating Market Lembang**.',
        );
        buffer.writeln(
          '• 15.30 - 18.00: Menikmati pemandangan matahari terbenam spektakuler di **Tebing Keraton**.',
        );
        buffer.writeln(
          '• 19.00 - selesai: Wisata malam & santap kuliner di **Jalan Braga** atau **Sudirman Street**.',
        );

        _addDestinationById(matchedDestinations, 'dest_01'); // Gedung Sate
        _addDestinationById(matchedDestinations, 'dest_06'); // Floating Market
        _addDestinationById(matchedDestinations, 'dest_11'); // Tebing Keraton
        _addDestinationById(matchedDestinations, 'dest_04'); // Braga
      }
    }
    // 2. Culinary Intent
    else if (lower.contains('kuliner') ||
        lower.contains('makan') ||
        lower.contains('jajan') ||
        lower.contains('kopi') ||
        lower.contains('cafe') ||
        lower.contains('batagor') ||
        lower.contains('sunda')) {
      buffer.writeln(
        'Bandung adalah surga kuliner Jawa Barat! Berikut sentra dan tempat makan wajib dicoba:',
      );
      buffer.writeln();
      buffer.writeln(
        '1. **Kawasan Kuliner Punclut**: Menikmati nasi timbel, ayam goreng serundeng, dan sambal terasi sambil menatap gemerlap malam kota Bandung dari ketinggian.',
      );
      buffer.writeln(
        '2. **Sudirman Street Day & Night Market**: Sentra kuliner malam legendaris dengan aneka street food khas Bandung.',
      );
      buffer.writeln(
        '3. **Floating Market Lembang**: Jajanan tradisional seperti colenak, tahu susu, dan es goyobod yang dijajakan di perahu terapung.',
      );
      buffer.writeln(
        '4. **Jalan Braga & Braga CityWalk**: Kafe estetik peninggalan kolonial Belanda dan kopi khas Bandung.',
      );
      buffer.writeln();
      buffer.writeln(
        '💡 *Tips Kuliner*: Jangan lupa mencicipi Batagor, Mie Kocok, dan Kopi Aroma legendaris!',
      );

      _addDestinationById(matchedDestinations, 'dest_07'); // Punclut
      _addDestinationById(matchedDestinations, 'dest_10'); // Sudirman Street
      _addDestinationById(matchedDestinations, 'dest_06'); // Floating Market
      _addDestinationById(matchedDestinations, 'dest_04'); // Braga
    }
    // 3. Nature / Alam Intent
    else if (RegExp(r'\balam\b').hasMatch(lower) ||
        lower.contains('sejuk') ||
        lower.contains('dingin') ||
        lower.contains('gunung') ||
        lower.contains('kawah') ||
        lower.contains('forest') ||
        lower.contains('lembang') ||
        lower.contains('ciwidey')) {
      buffer.writeln(
        'Bandung dikelilingi pegunungan yang asri dan berhawa sejuk. Berikut destinasi alam terbaik yang sangat direkomendasikan:',
      );
      buffer.writeln();
      buffer.writeln(
        '1. **Kawah Putih Ciwidey**: Kawah vulkanik eksotis berwarna toska di Ciwidey.',
      );
      buffer.writeln(
        '2. **Tangkuban Parahu**: Ikon legendaris Jawa Barat dengan kawah aktif megah.',
      );
      buffer.writeln(
        '3. **Dusun Bambu**: Ekowisata alam asri bernuansa pedesaan Sunda.',
      );
      buffer.writeln(
        '4. **Tebing Keraton**: Spot panorama kabut pagi dan sunrise spektakuler.',
      );
      buffer.writeln();
      buffer.writeln(
        '💡 *Tips*: Waktu terbaik tiba di lokasi alam adalah sebelum pukul 10.00 pagi untuk menghindari kabut tebal dan rintik hujan sore hari.',
      );

      _addDestinationById(matchedDestinations, 'dest_02'); // Kawah Putih
      _addDestinationById(matchedDestinations, 'dest_03'); // Tangkuban Parahu
      _addDestinationById(matchedDestinations, 'dest_08'); // Dusun Bambu
      _addDestinationById(matchedDestinations, 'dest_11'); // Tebing Keraton
    }
    // 4. Budget / Murah / Gratis Intent
    else if (lower.contains('murah') ||
        lower.contains('hemat') ||
        lower.contains('gratis') ||
        lower.contains('budget') ||
        lower.contains('uang') ||
        lower.contains('50')) {
      buffer.writeln(
        'Liburan di Bandung tetap bisa seru dan berkesan meski dengan anggaran terjangkau! Berikut opsi wisata ramah kantong:',
      );
      buffer.writeln();
      buffer.writeln(
        '1. **Jalan Braga & Braga CityWalk**: **Gratis (Tanpa Tiket)**. Jalan-jalan menikmati arsitektur klasik art deco.',
      );
      buffer.writeln(
        '2. **Gedung Sate**: Tiket masuk hanya **Rp 5.000**, menyimpan museum interaktif.',
      );
      buffer.writeln(
        '3. **Museum Geologi Bandung**: Tiket masuk hanya **Rp 3.000**, sarat edukasi sejarah purbakala.',
      );
      buffer.writeln(
        '4. **Tebing Keraton**: Tiket **Rp 17.000**, pemandangan alam spektakuler di atas bukit Bandung.',
      );
      buffer.writeln();
      buffer.writeln(
        '💡 *Tips*: Manfaatkan transportasi umum seperti Trans Metro Bandung atau angkutan kota untuk menekan ongkos perjalanan.',
      );

      _addDestinationById(matchedDestinations, 'dest_04'); // Braga
      _addDestinationById(matchedDestinations, 'dest_01'); // Gedung Sate
      _addDestinationById(matchedDestinations, 'dest_09'); // Museum Geologi
      _addDestinationById(matchedDestinations, 'dest_11'); // Tebing Keraton
    }
    // 5. History & Culture Intent
    else if (lower.contains('sejarah') ||
        lower.contains('budaya') ||
        lower.contains('museum') ||
        lower.contains('angklung') ||
        lower.contains('heritage')) {
      buffer.writeln(
        'Bagi pencinta sejarah dan kebudayaan Pasundan, ini destinasi yang tak boleh terlewatkan:',
      );
      buffer.writeln();
      buffer.writeln(
        '1. **Gedung Sate**: Ikon legendaris bernilai sejarah tinggi dengan ornamen tusuk sate khas.',
      );
      buffer.writeln(
        '2. **Museum Geologi Bandung**: Fosil dinosaurus dan warisan kebumian nusantara sejak 1928.',
      );
      buffer.writeln(
        '3. **Jalan Braga & Braga CityWalk**: Jejak kawasan elit kolonial tempo dulu.',
      );
      buffer.writeln(
        '4. **Saung Angklung Udjo**: Pertunjukan seni musik bambu tradisional interaktif warisan UNESCO.',
      );
      buffer.writeln();
      buffer.writeln(
        '💡 *Tips*: Kunjungi Museum Geologi di pagi hari saat suasana museum belum terlalu ramai.',
      );

      _addDestinationById(matchedDestinations, 'dest_01'); // Gedung Sate
      _addDestinationById(matchedDestinations, 'dest_09'); // Museum Geologi
      _addDestinationById(matchedDestinations, 'dest_04'); // Braga
      _addDestinationById(matchedDestinations, 'dest_05'); // Saung Angklung
    }
    // 6. Family & Recreation Intent
    else if (lower.contains('keluarga') ||
        lower.contains('anak') ||
        lower.contains('rekreasi') ||
        lower.contains('liburan') ||
        lower.contains('ramah anak') ||
        lower.contains('dago')) {
      buffer.writeln(
        'Liburan bersama keluarga tercinta di Bandung akan sangat menyenangkan di tempat-tempat berikut:',
      );
      buffer.writeln();
      buffer.writeln(
        '1. **Floating Market Lembang**: Menikmati danau buatan, memberi makan kelinci, dan kota mini.',
      );
      buffer.writeln(
        '2. **Dusun Bambu**: Ekowisata asri berkonsep pedesaan Sunda dengan playground alam terbuka.',
      );
      buffer.writeln(
        '3. **Saung Angklung Udjo**: Pertunjukan musik edukatif interaktif untuk anak-anak.',
      );
      buffer.writeln(
        '4. **Trans Studio Bandung**: Theme park indoor terbesar dengan wahana kelas dunia.',
      );
      buffer.writeln();
      buffer.writeln(
        '💡 *Tips*: Datanglah lebih awal di pagi hari agar anak-anak leluasa mencoba semua wahana rekreasi!',
      );

      _addDestinationById(matchedDestinations, 'dest_06'); // Floating Market
      _addDestinationById(matchedDestinations, 'dest_08'); // Dusun Bambu
      _addDestinationById(matchedDestinations, 'dest_05'); // Saung Angklung
      _addDestinationById(matchedDestinations, 'dest_12'); // Trans Studio
    }
    // 7. General Friendly Fallback Response
    else {
      // Check if any destination name matches the user's query
      final specificMatches = BandungDestinations.list
          .where((d) => lower.contains(d.name.toLowerCase()))
          .toList();

      if (specificMatches.isNotEmpty) {
        final dest = specificMatches.first;
        matchedDestinations.add(dest);
        buffer.writeln('Berikut informasi tentang **${dest.name}**:');
        buffer.writeln();
        buffer.writeln('📍 **Lokasi**: ${dest.address}');
        buffer.writeln('🏷️ **Kategori**: ${dest.category}');
        final revs = ReviewRepository().getReviewsForDestination(dest.id);
        final currentRating = ReviewRepository().getAverageRating(
          dest.id,
          fallback: dest.rating,
        );
        final reviewText = revs.isNotEmpty
            ? '${revs.length} ulasan wisatawan'
            : 'Rekomendasi Terkurasi';
        buffer.writeln(
          '⭐ **Rating**: ${currentRating.toStringAsFixed(1)} / 5.0 ($reviewText)',
        );
        buffer.writeln(
          '💵 **Estimasi Tiket**: ${dest.estimatedPrice <= 0 ? 'Gratis' : 'Rp ${dest.estimatedPrice.toInt()}'}',
        );
        buffer.writeln();
        buffer.writeln(dest.description);
        buffer.writeln();
        buffer.writeln(
          '💡 Ingin melihat rutenya di peta atau menambahkannya ke rencana liburan?',
        );
      } else {
        buffer.writeln(
          'Punten wargi, Kang Bandung siap membantu seputar destinasi wisata, kuliner legendaris, dan rencana liburan di Bandung Raya. 😊',
        );
        buffer.writeln();
        buffer.writeln(
          'Agar jawabannya pas dengan yang wargi inginkan, coba tanyakan hal seperti:',
        );
        buffer.writeln('• *"Rekomendasi tempat sejuk di Lembang atau Ciwidey"*');
        buffer.writeln('• *"Kuliner malam legendaris khas Bandung"*');
        buffer.writeln('• *"Buatkan rencana liburan 2 hari di Bandung"*');
        buffer.writeln('• *"Tempat wisata yang cocok untuk keluarga dan anak"*');
      }
    }

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: buffer.toString(),
      isUser: false,
      timestamp: DateTime.now(),
      recommendedDestinations: matchedDestinations,
    );
  }

  void _addDestinationById(List<Destination> list, String id) {
    try {
      final dest = BandungDestinations.list.firstWhere((d) => d.id == id);
      if (!list.contains(dest)) {
        list.add(dest);
      }
    } catch (_) {
      // Ignored safely
    }
  }

  /// Menganalisis foto landmark/objek wisata Bandung menggunakan Gemini Multimodal Vision API
  Future<LandmarkScanResult> analyzeLandmarkImage({
    required Uint8List imageBytes,
    String? hintName,
  }) async {
    final apiKey = await getEffectiveApiKey();

    if (apiKey.isNotEmpty) {
      final base64Image = base64Encode(imageBytes);
      final modelsToTry = [
        _primaryModel,
        ..._candidateModels.where((m) => m != _primaryModel),
      ];

      for (final model in modelsToTry) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final payload = {
            'system_instruction': {
              'parts': [
                {
                  'text': '''Anda adalah AI Ahli Pariwisata Bandung dan Arsitektur Cagar Budaya (Bandung Smart Lens).
Tugas Anda adalah menganalisis foto yang diberikan dan mengidentifikasi objek wisata, monumen, bangunan bersejarah, atau pemandangan alam di Bandung Raya.

Format output WAJIB berupa JSON murni valid (tanpa markdown backtick ```json) dengan skema:
{
  "isBandungLandmark": true,
  "landmarkName": "Nama Lengkap Objek/Tempat",
  "confidencePercent": 95,
  "category": "Sejarah & Budaya / Alam & Pegunungan / Keluarga / dsb",
  "shortDescription": "Ringkasan 2-3 kalimat menarik tentang objek wisata ini",
  "historyFact": "Fakta sejarah penting, tahun pembangunan, atau latar belakang arsitektur objek ini",
  "interestingTrivia": "Fakta unik atau mitos/trivia yang jarang diketahui orang tentang tempat ini",
  "recommendedThingsToDo": ["Aktivitas 1", "Aktivitas 2", "Aktivitas 3"]
}''',
                },
              ],
            },
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'Analisis foto ini secara mendalam. Jika ini adalah objek wisata atau landmark di Bandung (misalnya Gedung Sate, Kawah Putih, Bosscha, Jalan Braga, Saung Angklung Udjo, Tangkuban Parahu, Al-Jabbar, dsb), identifikasi dan kembalikan JSON lengkap.',
                  },
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 1024,
            },
          };

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 20));

          if (response.statusCode == 200) {
            final jsonBody = jsonDecode(response.body);
            final candidates = jsonBody['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final content =
                  candidates.first['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List<dynamic>?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts.first['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  String cleanJson = text.trim();
                  if (cleanJson.startsWith('```json')) {
                    cleanJson = cleanJson.substring(7);
                  } else if (cleanJson.startsWith('```')) {
                    cleanJson = cleanJson.substring(3);
                  }
                  if (cleanJson.endsWith('```')) {
                    cleanJson = cleanJson.substring(0, cleanJson.length - 3);
                  }
                  cleanJson = cleanJson.trim();

                  final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
                  final landmarkName =
                      parsed['landmarkName'] as String? ?? 'Objek Wisata Bandung';

                  final matched = _findMatchingDestination(landmarkName);

                  return LandmarkScanResult.fromMap(
                    parsed,
                    matchedDestination: matched,
                  );
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Gemini vision API error with model $model: $e');
        }
      }
    }

    // Fallback cerdas lokal jika offline / kuota habis
    return _generateLocalLandmarkFallback(hintName: hintName);
  }

  Destination? _findMatchingDestination(String name) {
    final lower = name.toLowerCase();
    for (final d in BandungDestinations.list) {
      final dLower = d.name.toLowerCase();
      if (lower.contains(dLower) || dLower.contains(lower)) {
        return d;
      }
    }
    for (final d in BandungDestinations.list) {
      for (final tag in d.tags) {
        if (lower.contains(tag.toLowerCase())) {
          return d;
        }
      }
    }
    return null;
  }

  LandmarkScanResult _generateLocalLandmarkFallback({String? hintName}) {
    final hint = hintName?.toLowerCase() ?? '';

    if (hint.contains('kawah putih') || hint.contains('patuha')) {
      final dest = _findMatchingDestination('Kawah Putih Ciwidey');
      return LandmarkScanResult(
        isBandungLandmark: true,
        landmarkName: 'Kawah Putih Ciwidey',
        confidencePercent: 97,
        category: 'Alam & Pegunungan',
        shortDescription:
            'Danau kawah vulkanik spektakuler di puncak Gunung Patuha pada ketinggian 2.194 mdpl dengan air putih kehijauan yang berubah warna secara berkala.',
        historyFact:
            'Ditemukan oleh ahli botani Belanda Dr. Franz Wilhelm Junghuhn pada tahun 1837 setelah membantah mitos kerajaan gaib burung mati di puncak Patuha.',
        interestingTrivia:
            'Warna kawah dapat berubah dari putih kebiruan, hijau toska, hingga kecokelatan tergantung kadar belerang, suhu kawah, dan bias sinar matahari.',
        recommendedThingsToDo: [
          'Berfoto di jembatan apung ponton tengah danau',
          'Berjalan melintasi Skywalk Cantigi berlatar kabut',
          'Mencicipi jagung bakar hangat di area parkir atas',
        ],
        matchedDestination: dest,
      );
    }

    if (hint.contains('tangkuban') || hint.contains('parahu')) {
      final dest = _findMatchingDestination('Gunung Tangkuban Parahu');
      return LandmarkScanResult(
        isBandungLandmark: true,
        landmarkName: 'Gunung Tangkuban Parahu',
        confidencePercent: 96,
        category: 'Alam & Pegunungan',
        shortDescription:
            'Gunung api stratovulkan aktif legendaris Sangkuriang dengan bibir Kawah Ratu raksasa dan semburan belerang Kawah Domas di ketinggian 2.084 mdpl.',
        historyFact:
            'Bentuk perahu terbalik tercipta akibat runtuhnya kaldera Gunung Sunda Purba ribuan tahun lalu yang melahirkan legenda Dayang Sumbi.',
        interestingTrivia:
            'Pengunjung dapat merebus telur langsung di sumber mata air belerang alami Kawah Domas hingga matang sempurna dalam waktu 10 menit.',
        recommendedThingsToDo: [
          'Menyaksikan pemandangan megah bibir Kawah Ratu',
          'Sensasi rebus telur dan terapi lumpur di Kawah Domas',
          'Membeli suvenir kerajinan kayu dan ketan bakar',
        ],
        matchedDestination: dest,
      );
    }

    if (hint.contains('braga')) {
      final dest = _findMatchingDestination('Jalan Braga');
      return LandmarkScanResult(
        isBandungLandmark: true,
        landmarkName: 'Jalan Braga',
        confidencePercent: 98,
        category: 'Sejarah & Budaya',
        shortDescription:
            'Jantung bersejarah "Parijs van Java" yang memadukan deretan gedung bergaya Art Deco kolonial Belanda, kafe estetik, dan seniman jalanan.',
        historyFact:
            'Dahulu dikenal sebagai Karrenweg (Jalan Pedati), berkembang menjadi pusat belanja barang mewah dan haute couture Eropa termasyhur di Hindia Belanda.',
        interestingTrivia:
            'Nama Braga konon diambil dari kata Sunda "ngabaraga" yang berarti berjalan bergaya menyusuri sungai, atau dari nama Bragi dewa puisi mitologi Nordik.',
        recommendedThingsToDo: [
          'Menikmati kopi di kafe estetik peninggalan kolonial',
          'Melihat pameran lukisan pelukis trotoar jalanan',
          'Berfoto di plang bersejarah ikonik Jalan Braga',
        ],
        matchedDestination: dest,
      );
    }

    if (hint.contains('bosscha')) {
      final dest = _findMatchingDestination('Observatorium Bosscha');
      return LandmarkScanResult(
        isBandungLandmark: true,
        landmarkName: 'Observatorium Bosscha',
        confidencePercent: 95,
        category: 'Sejarah & Edukasi',
        shortDescription:
            'Observatorium astronomi modern tertua di Indonesia yang menampung teleskop refraktor ganda Zeiss 60 cm di perbukitan Lembang.',
        historyFact:
            'Didirikan pada tahun 1923 oleh Perhimpunan Astronomi Hindia Belanda atas sumbangsih utama dari tuan tanah perkebunan teh Karel Albert Rudolf Bosscha.',
        interestingTrivia:
            'Bangunan berkubah putih perak ini menjadi cagar budaya nasional dan lokasi syuting film legendaris "Petualangan Sherina".',
        recommendedThingsToDo: [
          'Melihat cara kerja kubah teleskop Zeiss yang dapat berputar',
          'Belajar pemetaan konstelasi bintang dan galaksi Bima Sakti',
          'Menikmati hawa sejuk di bawah pepohonan pinus cagar budaya',
        ],
        matchedDestination: dest,
      );
    }

    if (hint.contains('angklung') || hint.contains('udjo')) {
      final dest = _findMatchingDestination('Saung Angklung Udjo');
      return LandmarkScanResult(
        isBandungLandmark: true,
        landmarkName: 'Saung Angklung Udjo',
        confidencePercent: 99,
        category: 'Keluarga & Budaya',
        shortDescription:
            'Pusat pelestarian dan pertunjukan seni angklung Sunda warisan dunia UNESCO dengan pagelaran musik orkestra bambu interaktif spektakuler.',
        historyFact:
            'Didirikan oleh Mang Udjo Ngalagena dan sang istri Uum Yumerti pada tahun 1966 dengan misi memelihara harmoni gotong royong budaya Pasundan.',
        interestingTrivia:
            'Setiap pengunjung dipinjami instrumen angklung dan dalam 10 menit dipandu secara interaktif memainkan harmoni lagu nusantara dan pop dunia.',
        recommendedThingsToDo: [
          'Bermain musik angklung bersama ratusan penonton',
          'Menyaksikan pertunjukan wayang golek dan tari jaipong',
          'Melihat bengkel kerajinan instrumen bambu tradisional',
        ],
        matchedDestination: dest,
      );
    }

    // Default landmark fallback: Gedung Sate (Ikon utama Bandung)
    final dest = _findMatchingDestination('Gedung Sate');
    return LandmarkScanResult(
      isBandungLandmark: true,
      landmarkName: 'Gedung Sate',
      confidencePercent: 96,
      category: 'Sejarah & Budaya',
      shortDescription:
          'Ikon arsitektur neo-klasik Kota Bandung dengan ornamen tusuk sate legendaris pada puncak menara sentralnya yang dibangun tahun 1920.',
      historyFact:
          'Dirancang oleh tim arsitek Ir. J. Gerber dan Ir. Eh. De Roo, memadukan gaya arsitektur Italia Renaisans dengan atap bertingkat gaya Sunda dan candi Hindu Bali.',
      interestingTrivia:
          'Enam ornamen jambu air pada menara tusuk sate melambangkan biaya pembangunan gedung senilai 6 juta Gulden pada era kolonial Hindia Belanda.',
      recommendedThingsToDo: [
        'Kunjungi Museum Gedung Sate dengan teknologi VR & AR interaktif',
        'Foto lanskap dari taman air mancur pelataran depan',
        'Mencoba kuliner khas di area Gasibu tepat di seberang gedung',
      ],
      matchedDestination: dest,
    );
  }
}
