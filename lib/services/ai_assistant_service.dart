import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy/dummy_destinations.dart';
import '../models/chat_message.dart';
import '../models/destination.dart';

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  static const String _keyGeminiApiKey = 'bandunghub_gemini_api_key';

  // Model name - using gemini-1.5-flash for rapid, lightweight travel responses
  static const String _geminiModel = 'gemini-1.5-flash';

  // System Prompt for Bandung Tourism Companion
  static const String _systemPrompt = '''
Anda adalah 'Kang Bandung', asisten pemandu wisata cerdas, ramah, dan berpengalaman untuk aplikasi BandungHub.
Tugas Anda:
1. Memberikan rekomendasi destinasi wisata di Kota dan Kabupaten Bandung yang sesuai preferensi pengguna.
2. Memberikan tips perjalanan realistis: waktu terbaik berkunjung, kondisi cuaca sejuk (misal: Lembang/Ciwidey), perkiraan biaya tiket, dan kuliner khas sekitar.
3. Sebutkan nama-nama destinasi wisata Bandung secara jelas.
4. Gunakan gaya bahasa Indonesia yang santun, hangat, dan ramah dengan sisipan salam khas Sunda seperti 'Sampurasun!', 'Wilujeng sumping', 'Hatur nuhun'.
5. Bersikap ringkas, padat, dan terstruktur.
''';

  // API Key management
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGeminiApiKey);
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
    return key != null && key.isNotEmpty;
  }

  // Send message with automatic Gemini API -> Smart Local Fallback
  Future<ChatMessage> processMessage(String userPrompt) async {
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

    final apiKey = await getApiKey();

    // 1. Try Gemini API if API key is provided
    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final geminiResponse = await _queryGeminiApi(cleanPrompt, apiKey);
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

    // 2. Intelligent Local Heuristic Engine Fallback (100% reliable offline/fallback)
    return _generateLocalHeuristicResponse(cleanPrompt);
  }

  // Query Gemini REST endpoint
  Future<String?> _queryGeminiApi(String prompt, String apiKey) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey',
    );

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$_systemPrompt\n\nPertanyaan Pengguna: $prompt'},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 800},
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String?;
        }
      }
    } else {
      debugPrint(
        'Gemini API error code: ${response.statusCode}, body: ${response.body}',
      );
    }
    return null;
  }

  // Find destinations from DummyDestinations mentioned in the text
  List<Destination> _extractMentionedDestinations(String text) {
    final lower = text.toLowerCase();
    final matched = <Destination>[];

    for (final dest in DummyDestinations.list) {
      if (lower.contains(dest.name.toLowerCase())) {
        matched.add(dest);
      }
    }
    return matched;
  }

  // Smart Local Rule-Based NLP Heuristic Engine
  ChatMessage _generateLocalHeuristicResponse(String query) {
    final lower = query.toLowerCase();
    final buffer = StringBuffer();
    final List<Destination> matchedDestinations = [];

    buffer.writeln(
      'Sampurasun! Wilujeng sumping di layanan asisten cerdas BandungHub! 🙏',
    );
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
    // 7. General Friendly Bandung Recommendation
    else {
      buffer.writeln(
        'Senang sekali bisa membantu rencana perjalanan Anda ke Bandung! Berdasarkan rekomendasi terpopuler wisatawan BandungHub, berikut destinasi unggulan kami:',
      );
      buffer.writeln();
      buffer.writeln(
        '• **Tangkuban Parahu & Kawah Putih** untuk pesona pemandangan alam vulkanik.',
      );
      buffer.writeln(
        '• **Floating Market Lembang** untuk suasana santai keluarga dan kuliner terapung.',
      );
      buffer.writeln(
        '• **Gedung Sate & Jalan Braga** untuk wisata arsitektur bersejarah.',
      );
      buffer.writeln(
        '• **Kawasan Kuliner Punclut** untuk santap malam berpanorama lampu kota.',
      );
      buffer.writeln();
      buffer.writeln(
        'Silakan tanyakan hal spesifik, seperti: *"rekomendasi wisata alam sejuk"*, *"kuliner malam ramah kantong"*, atau *"itinerary 2 hari di Lembang"*!',
      );

      _addDestinationById(matchedDestinations, 'dest_03'); // Tangkuban
      _addDestinationById(matchedDestinations, 'dest_02'); // Kawah Putih
      _addDestinationById(matchedDestinations, 'dest_06'); // Floating Market
      _addDestinationById(matchedDestinations, 'dest_01'); // Gedung Sate
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
      final dest = DummyDestinations.list.firstWhere((d) => d.id == id);
      if (!list.contains(dest)) {
        list.add(dest);
      }
    } catch (_) {
      // Ignored safely
    }
  }
}
