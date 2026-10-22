import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sources/bandung_destinations.dart';
import '../models/chat_message.dart';
import '../models/destination.dart';

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  static const String _keyGeminiApiKey = 'bandunghub_gemini_api_key';
  static const String _keyChatHistory = 'bandunghub_ai_chat_history';

  // Default API Key
  static const String _defaultApiKey =
      'AQ.Ab8RN6IVpiZNUHhYUFWnjoN5Kx-SuV8AvpJgNY7_NUpFm-AB2Q';

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
Anda adalah 'Kang Bandung', asisten virtual AI yang cerdas, berwawasan luas, dan pemandu resmi di aplikasi BandungHub.

KEPRIBADIAN DAN IDENTITAS:
- Berbahasa Indonesia yang hangat, sopan, santun, dan luwes dengan sentuhan ramah khas Sunda ("Someah Hade ka Semah"). Boleh menyelipkan sapaan akrab seperti 'Sampurasun!', 'Wilujeng sumping', 'Punten', 'Hatur nuhun pisan', 'Mangga', 'Akang/Teteh/Wargi'.
- Anda adalah AI yang serba tahu, berwawasan luas, cerdas, dan selalu siap membantu pengguna dalam topik apa pun.

SPESIALISASI UTAMA:
- Sangat menguasai destinasi wisata di Kota Bandung, Kabupaten Bandung (Ciwidey, Pangalengan), Bandung Barat (Lembang), Cimahi, dan sekitarnya.
- Pakar kuliner khas Sunda/Bandung (seblak, batagor, mie kocok, lotek, surabi, kupat tahu, cafe & resto hits).
- Paham kebudayaan, sejarah Bandung (Gedung Sate, KAA, Jalan Braga), dan kebiasaan lokal.
- Paham fitur aplikasi BandungHub: Beranda (ringkasan & cuaca), Jelajah (kategori & filter budget), Peta (navigasi lokasi), Rencana (itinerary harian & budget liburan), dan Mini Game (Bocchi Jumpy arkade).

FLEKSIBILITAS & PERCAKAPAN UMUM (PENTING):
- JANGAN PERNAH menolak pertanyaan pengguna secara kaku atau kaku membatasi percakapan!
- Jika pengguna bertanya tentang topik umum di luar Bandung (seperti tokoh, sejarah umum, teknologi, sains, musik, rekomendasi umum, percakapan santai, dll):
  JAWABLAH SECARA LENGKAP, AKURAT, DAN CERDAS sesuai konteks pertanyaan pengguna dengan gaya bahasa ramah Kang Bandung. Jangan pernah menolak atau mengatakan "kurang paham karena di luar Bandung". Berikan jawaban yang memuaskan dan berbobot!
- Selalu berikan jawaban yang tuntas, berbobot, terstruktur rapi (gunakan poin-poin/bullet points dan format tebal/bold bila sesuai), dan jangan menggantung atau terpotong.
''';

  // API Key management
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
  }

  Future<String> getEffectiveApiKey() async {
    final customKey = await getApiKey();
    if (customKey != null && customKey.trim().isNotEmpty) {
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

    // 0. Greeting & Casual Inquiry Intent (e.g. "aku mau tanya", "halo", "bisa bantu")
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
        'Tugas saya menemani wargi merencanakan liburan terbaik di Bandung Raya—mulai dari mencari destinasi alam pegunungan, kuliner Sunda legendaris, rute navigasi peta, hingga menyusun jadwal itinerary harian.',
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
        '1. **Kawasan Kuliner Punclut** — Menikmati nasi timbel, ayam goreng serundeng, dan sambal terasi sambil menatap gemerlap malam kota Bandung dari ketinggian.',
      );
      buffer.writeln(
        '2. **Sudirman Street Day & Night Market** — Sentra kuliner malam legendaris dengan aneka street food khas Bandung.',
      );
      buffer.writeln(
        '3. **Floating Market Lembang** — Jajanan tradisional seperti colenak, tahu susu, dan es goyobod yang dijajakan di perahu terapung.',
      );
      buffer.writeln(
        '4. **Jalan Braga & Braga CityWalk** — Kafe estetik peninggalan kolonial Belanda dan kopi khas Bandung.',
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
        '1. **Kawah Putih Ciwidey** — Kawah vulkanik eksotis berwarna toska di Ciwidey.',
      );
      buffer.writeln(
        '2. **Tangkuban Parahu** — Ikon legendaris Jawa Barat dengan kawah aktif megah.',
      );
      buffer.writeln(
        '3. **Dusun Bambu** — Ekowisata alam asri bernuansa pedesaan Sunda.',
      );
      buffer.writeln(
        '4. **Tebing Keraton** — Spot panorama kabut pagi dan sunrise spektakuler.',
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
        '1. **Jalan Braga & Braga CityWalk** — **Gratis (Tanpa Tiket)**. Jalan-jalan menikmati arsitektur klasik art deco.',
      );
      buffer.writeln(
        '2. **Gedung Sate** — Tiket masuk hanya **Rp 5.000**, menyimpan museum interaktif.',
      );
      buffer.writeln(
        '3. **Museum Geologi Bandung** — Tiket masuk hanya **Rp 3.000**, sarat edukasi sejarah purbakala.',
      );
      buffer.writeln(
        '4. **Tebing Keraton** — Tiket **Rp 17.000**, pemandangan alam spektakuler di atas bukit Bandung.',
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
        '1. **Gedung Sate** — Ikon legendaris bernilai sejarah tinggi dengan ornamen tusuk sate khas.',
      );
      buffer.writeln(
        '2. **Museum Geologi Bandung** — Fosil dinosaurus dan warisan kebumian nusantara sejak 1928.',
      );
      buffer.writeln(
        '3. **Jalan Braga & Braga CityWalk** — Jejak kawasan elit kolonial tempo dulu.',
      );
      buffer.writeln(
        '4. **Saung Angklung Udjo** — Pertunjukan seni musik bambu tradisional interaktif warisan UNESCO.',
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
        '1. **Floating Market Lembang** — Menikmati danau buatan, memberi makan kelinci, dan kota mini.',
      );
      buffer.writeln(
        '2. **Dusun Bambu** — Ekowisata asri berkonsep pedesaan Sunda dengan playground alam terbuka.',
      );
      buffer.writeln(
        '3. **Saung Angklung Udjo** — Pertunjukan musik edukatif interaktif untuk anak-anak.',
      );
      buffer.writeln(
        '4. **Trans Studio Bandung** — Theme park indoor terbesar dengan wahana kelas dunia.',
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
        buffer.writeln(
          '⭐ **Rating**: ${dest.rating} / 5.0 (${dest.reviewCount} ulasan)',
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
}
