class AppConstants {
  static const String appName = 'BandungHub';
  static const String appTagline = 'Your Smart Bandung Travel Companion';
  static const String appVersion = '1.0.0';

  // Bandung geographical center coordinates
  static const double bandungLatitude = -6.917464;
  static const double bandungLongitude = 107.619123;

  // Categories
  static const List<String> categories = [
    'Semua',
    'Alam',
    'Kuliner',
    'Sejarah',
    'Keluarga',
    'Hiburan',
  ];

  // Tile provider attribution
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
