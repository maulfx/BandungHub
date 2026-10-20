import 'package:intl/intl.dart';

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
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(
      code: 'IDR',
      name: 'Rupiah Indonesia',
      symbol: 'Rp',
      flag: '🇮🇩',
      rateToIdr: 1.0,
    ),
    CurrencyInfo(
      code: 'USD',
      name: 'Dolar Amerika Serikat',
      symbol: '\$',
      flag: '🇺🇸',
      rateToIdr: 16250.0,
    ),
    CurrencyInfo(
      code: 'EUR',
      name: 'Euro Uni Eropa',
      symbol: '€',
      flag: '🇪🇺',
      rateToIdr: 17600.0,
    ),
    CurrencyInfo(
      code: 'SGD',
      name: 'Dolar Singapura',
      symbol: 'S\$',
      flag: '🇸🇬',
      rateToIdr: 12200.0,
    ),
    CurrencyInfo(
      code: 'MYR',
      name: 'Ringgit Malaysia',
      symbol: 'RM',
      flag: '🇲🇾',
      rateToIdr: 3650.0,
    ),
    CurrencyInfo(
      code: 'JPY',
      name: 'Yen Jepang',
      symbol: '¥',
      flag: '🇯🇵',
      rateToIdr: 105.0,
    ),
    CurrencyInfo(
      code: 'AUD',
      name: 'Dolar Australia',
      symbol: 'A\$',
      flag: '🇦🇺',
      rateToIdr: 10650.0,
    ),
    CurrencyInfo(
      code: 'CNY',
      name: 'Yuan Tiongkok',
      symbol: '¥',
      flag: '🇨🇳',
      rateToIdr: 2250.0,
    ),
    CurrencyInfo(
      code: 'SAR',
      name: 'Riyal Arab Saudi',
      symbol: 'SR',
      flag: '🇸🇦',
      rateToIdr: 4330.0,
    ),
    CurrencyInfo(
      code: 'GBP',
      name: 'Poundsterling Inggris',
      symbol: '£',
      flag: '🇬🇧',
      rateToIdr: 20850.0,
    ),
  ];

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
    final targetDt = bandungDt.add(Duration(hours: targetTz.diffHoursFromBandung));
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
