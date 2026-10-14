class AppDateUtils {
  static const List<String> monthNames = [
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

  static const List<String> monthShortNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String formatDate(DateTime date) {
    final day = date.day;
    final month = monthShortNames[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  static String formatFullDate(DateTime date) {
    final dayName = dayNames[date.weekday - 1];
    final day = date.day;
    final month = monthNames[date.month - 1];
    final year = date.year;
    return '$dayName, $day $month $year';
  }
}
