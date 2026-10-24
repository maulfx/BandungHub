import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double rateToIdr;

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.rateToIdr,
  });

  CurrencyInfo copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    double? rateToIdr,
  }) {
    return CurrencyInfo(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      rateToIdr: rateToIdr ?? this.rateToIdr,
    );
  }
}

class TimezoneInfo {
  final String code;
  final String cityName;
  final String country;
  final String flag;
  final int offsetFromUtcHours;

  const TimezoneInfo({
    required this.code,
    required this.cityName,
    required this.country,
    required this.flag,
    required this.offsetFromUtcHours,
  });

  int get diffHoursFromBandung => offsetFromUtcHours - 7;

  String get diffDescription {
    final diff = diffHoursFromBandung;
    if (diff == 0) return 'Waktu sama dengan Bandung (WIB)';
    if (diff > 0) return '+$diff jam lebih cepat dari Bandung';
    return '$diff jam lebih lambat dari Bandung';
  }
}

class TravelConverterService {
  static const String _keyRates = 'bandunghub_cached_currency_rates';
  static const String _keyRatesTimestamp = 'bandunghub_cached_currency_time';

  static final List<CurrencyInfo> _defaultCurrencies = [
    const CurrencyInfo(
      code: 'IDR',
      name: 'Rupiah Indonesia',
      symbol: 'Rp',
      flag: '🇮🇩',
      rateToIdr: 1.0,
    ),
    const CurrencyInfo(
      code: 'USD',
      name: 'Dolar Amerika Serikat',
      symbol: '\$',
      flag: '🇺🇸',
      rateToIdr: 16250.0,
    ),
    const CurrencyInfo(
      code: 'EUR',
      name: 'Euro Uni Eropa',
      symbol: '€',
      flag: '🇪🇺',
      rateToIdr: 17600.0,
    ),
    const CurrencyInfo(
      code: 'SGD',
      name: 'Dolar Singapura',
      symbol: 'S\$',
      flag: '🇸🇬',
      rateToIdr: 12200.0,
    ),
    const CurrencyInfo(
      code: 'MYR',
      name: 'Ringgit Malaysia',
      symbol: 'RM',
      flag: '🇲🇾',
      rateToIdr: 3650.0,
    ),
    const CurrencyInfo(
      code: 'JPY',
      name: 'Yen Jepang',
      symbol: '¥',
      flag: '🇯🇵',
      rateToIdr: 105.0,
    ),
    const CurrencyInfo(
      code: 'AUD',
      name: 'Dolar Australia',
      symbol: 'A\$',
      flag: '🇦🇺',
      rateToIdr: 10650.0,
    ),
    const CurrencyInfo(
      code: 'CNY',
      name: 'Yuan Tiongkok',
      symbol: '¥',
      flag: '🇨🇳',
      rateToIdr: 2250.0,
    ),
    const CurrencyInfo(
      code: 'SAR',
      name: 'Riyal Arab Saudi',
      symbol: 'SR',
      flag: '🇸🇦',
      rateToIdr: 4330.0,
    ),
    const CurrencyInfo(
      code: 'GBP',
      name: 'Poundsterling Inggris',
      symbol: '£',
      flag: '🇬🇧',
      rateToIdr: 20850.0,
    ),
  ];

  static List<CurrencyInfo> _supportedCurrencies = List.from(_defaultCurrencies);
  static List<CurrencyInfo> get supportedCurrencies => _supportedCurrencies;

  static DateTime? lastRatesUpdated;
  static bool isLiveRates = false;
  static bool isFetching = false;

  /// Load cached rates on app launch
  static Future<void> loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_keyRates);
      final timeMillis = prefs.getInt(_keyRatesTimestamp);

      if (timeMillis != null) {
        lastRatesUpdated = DateTime.fromMillisecondsSinceEpoch(timeMillis);
      }

      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> rateMap = jsonDecode(cachedJson);
        _applyRateMap(rateMap);
      }
    } catch (e) {
      debugPrint('Error loading cached currency rates: $e');
    }
  }

  /// Apply rate mapping into _supportedCurrencies
  static void _applyRateMap(Map<String, dynamic> rateMap) {
    _supportedCurrencies = _defaultCurrencies.map((c) {
      if (c.code == 'IDR') return c;
      if (rateMap.containsKey(c.code)) {
        final val = (rateMap[c.code] as num).toDouble();
        if (val > 0) {
          return c.copyWith(rateToIdr: val);
        }
      }
      return c;
    }).toList();
  }

  /// Fetch live exchange rates from Open Exchange API
  static Future<bool> fetchLiveRates({bool force = false}) async {
    // If recently fetched in memory (e.g. within 10 minutes) and not forced, reuse
    if (!force &&
        isLiveRates &&
        lastRatesUpdated != null &&
        DateTime.now().difference(lastRatesUpdated!).inMinutes < 10) {
      return true;
    }

    if (isFetching) return false;
    isFetching = true;

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.containsKey('IDR')) {
          final idrRate = (rates['IDR'] as num).toDouble();
          final Map<String, double> calculatedRateToIdr = {};

          for (final cur in _defaultCurrencies) {
            if (cur.code == 'IDR') {
              calculatedRateToIdr['IDR'] = 1.0;
            } else if (rates.containsKey(cur.code)) {
              final codeRate = (rates[cur.code] as num).toDouble();
              if (codeRate > 0) {
                calculatedRateToIdr[cur.code] = idrRate / codeRate;
              }
            }
          }

          _applyRateMap(calculatedRateToIdr);
          isLiveRates = true;
          lastRatesUpdated = DateTime.now();

          // Persist to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyRates, jsonEncode(calculatedRateToIdr));
          await prefs.setInt(
            _keyRatesTimestamp,
            lastRatesUpdated!.millisecondsSinceEpoch,
          );

          return true;
        }
      }
    } catch (e) {
      debugPrint(
        'Failed to fetch live exchange rates: $e. Falling back to cache/default.',
      );
    } finally {
      isFetching = false;
    }

    // Fallback: load cache if live failed
    await loadCachedRates();
    return false;
  }

  static const List<TimezoneInfo> supportedTimezones = [
    TimezoneInfo(
      code: 'WIB',
      cityName: 'Bandung (Pusat Wisata)',
      country: 'Indonesia Barat',
      flag: '🇮🇩',
      offsetFromUtcHours: 7,
    ),
    TimezoneInfo(
      code: 'WITA',
      cityName: 'Bali / Makassar',
      country: 'Indonesia Tengah',
      flag: '🇮🇩',
      offsetFromUtcHours: 8,
    ),
    TimezoneInfo(
      code: 'WIT',
      cityName: 'Jayapura / Maluku',
      country: 'Indonesia Timur',
      flag: '🇮🇩',
      offsetFromUtcHours: 9,
    ),
    TimezoneInfo(
      code: 'SGT',
      cityName: 'Singapura & Kuala Lumpur',
      country: 'Singapura / Malaysia',
      flag: '🇸🇬',
      offsetFromUtcHours: 8,
    ),
    TimezoneInfo(
      code: 'JST',
      cityName: 'Tokyo & Kyoto',
      country: 'Jepang',
      flag: '🇯🇵',
      offsetFromUtcHours: 9,
    ),
    TimezoneInfo(
      code: 'AEST',
      cityName: 'Sydney & Melbourne',
      country: 'Australia',
      flag: '🇦🇺',
      offsetFromUtcHours: 10,
    ),
    TimezoneInfo(
      code: 'AST',
      cityName: 'Mekkah & Riyadh',
      country: 'Arab Saudi',
      flag: '🇸🇦',
      offsetFromUtcHours: 3,
    ),
    TimezoneInfo(
      code: 'CET',
      cityName: 'Amsterdam & Paris',
      country: 'Uni Eropa',
      flag: '🇪🇺',
      offsetFromUtcHours: 1,
    ),
    TimezoneInfo(
      code: 'GMT',
      cityName: 'London',
      country: 'Inggris',
      flag: '🇬🇧',
      offsetFromUtcHours: 0,
    ),
    TimezoneInfo(
      code: 'EST',
      cityName: 'New York',
      country: 'Amerika Serikat',
      flag: '🇺🇸',
      offsetFromUtcHours: -5,
    ),
  ];

  /// Find currency by code
  static CurrencyInfo getCurrency(String code) {
    return supportedCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => supportedCurrencies.first,
    );
  }

  /// Convert amount between any two currencies
  static double convertCurrency({
    required double amount,
    required String fromCode,
    required String toCode,
  }) {
    if (amount <= 0) return 0.0;
    final from = getCurrency(fromCode);
    final to = getCurrency(toCode);

    // Convert from origin to IDR, then to target
    final amountInIdr = amount * from.rateToIdr;
    return amountInIdr / to.rateToIdr;
  }

  /// Format money output with appropriate precision
  static String formatCurrency(double amount, String code) {
    final cur = getCurrency(code);
    if (code.toUpperCase() == 'IDR') {
      final f = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '${cur.symbol} ',
        decimalDigits: 0,
      );
      return f.format(amount);
    } else if (code.toUpperCase() == 'JPY') {
      final f = NumberFormat.currency(
        symbol: '${cur.symbol} ',
        decimalDigits: 0,
      );
      return f.format(amount);
    } else {
      final f = NumberFormat.currency(
        symbol: '${cur.symbol} ',
        decimalDigits: 2,
      );
      return f.format(amount);
    }
  }

  /// Get live current time in a given timezone
  static DateTime getCurrentTimeInTimezone(TimezoneInfo tz) {
    final utc = DateTime.now().toUtc();
    return utc.add(Duration(hours: tz.offsetFromUtcHours));
  }

  /// Convert a specific Bandung time (hour:minute) to a target timezone
  static String convertBandungTimeToTarget({
    required int bandungHour,
    required int bandungMinute,
    required TimezoneInfo targetTz,
  }) {
    final now = DateTime.now();
    final bandungDt = DateTime(
      now.year,
      now.month,
      now.day,
      bandungHour,
      bandungMinute,
    );
    final targetDt = bandungDt.add(
      Duration(hours: targetTz.diffHoursFromBandung),
    );
    return DateFormat('HH:mm').format(targetDt);
  }

  /// Format Bandung operational hours (e.g. 08:00 - 17:00 WIB) in target timezone
  static String getOperationalHoursInTimezone({
    required TimezoneInfo targetTz,
    int openHourWib = 8,
    int closeHourWib = 17,
  }) {
    final openStr = convertBandungTimeToTarget(
      bandungHour: openHourWib,
      bandungMinute: 0,
      targetTz: targetTz,
    );
    final closeStr = convertBandungTimeToTarget(
      bandungHour: closeHourWib,
      bandungMinute: 0,
      targetTz: targetTz,
    );
    return '$openStr - $closeStr ${targetTz.code}';
  }

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Format date in clean Indonesian without external locale dependencies
  static String formatIndonesianDate(DateTime dt) {
    final day = _dayNames[dt.weekday - 1];
    final month = _monthNames[dt.month - 1];
    return '$day, ${dt.day} $month ${dt.year}';
  }
}
