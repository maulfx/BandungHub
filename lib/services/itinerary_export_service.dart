import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/date_utils.dart';
import '../models/itinerary.dart';

/// Service untuk mengekspor dan membagikan rencana perjalanan (Itinerary)
/// Mendukung Plain Text (WhatsApp/Telegram), JSON Data Cadangan, dan HTML Siap Cetak.
class ItineraryExportService {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Menghasilkan format teks rapi dengan struktur dan emoji untuk WhatsApp, Telegram, Email, dll.
  static String generatePlainText(Itinerary itinerary) {
    final buffer = StringBuffer();
    final endDate = itinerary.startDate.add(
      Duration(days: itinerary.durationDays - 1),
    );

    buffer.writeln('========================================');
    buffer.writeln('🎒 ITINERARY WISATA BANDUNGHUB');
    buffer.writeln('📌 ${itinerary.title.toUpperCase()}');
    buffer.writeln('========================================');
    buffer.writeln(
      '📅 Periode     : ${AppDateUtils.formatDate(itinerary.startDate)} s.d. ${AppDateUtils.formatDate(endDate)} (${itinerary.durationDays} Hari)',
    );
    buffer.writeln('👥 Jumlah Tamu : ${itinerary.numberOfPeople} Orang');
    buffer.writeln(
      '🏷️ Status Data : ${itinerary.syncStatus == "synced" ? "Tersinkronisasi Cloud" : "Penyimpanan Lokal"}',
    );
    if (itinerary.savedHash != null && itinerary.savedHash!.isNotEmpty) {
      buffer.writeln('🔒 Hash SHA-256: ${itinerary.savedHash}');
    }
    buffer.writeln('');

    buffer.writeln('💰 RINGKASAN ESTIMASI BIAYA:');
    buffer.writeln('----------------------------------------');
    buffer.writeln(
      '• Tiket Masuk   : ${_currencyFormatter.format(itinerary.totalTicketCost)}',
    );
    buffer.writeln(
      '• Transportasi  : ${_currencyFormatter.format(itinerary.transportationCost)}',
    );
    buffer.writeln(
      '• Kuliner/Makan : ${_currencyFormatter.format(itinerary.foodCost)}',
    );
    if (itinerary.additionalCost > 0) {
      buffer.writeln(
        '• Biaya Lainnya : ${_currencyFormatter.format(itinerary.additionalCost)}',
      );
    }
    buffer.writeln(
      '• TOTAL ESTIMASI: ${_currencyFormatter.format(itinerary.totalEstimatedBudget)}',
    );
    buffer.writeln('');

    buffer.writeln('🗺️ RUTE & JADWAL PERJALANAN:');
    buffer.writeln('----------------------------------------');

    final itemsByDay = itinerary.itemsByDay;
    for (int day = 1; day <= itinerary.durationDays; day++) {
      final dayDate = itinerary.startDate.add(Duration(days: day - 1));
      buffer.writeln('📍 HARI $day (${AppDateUtils.formatFullDate(dayDate)}):');

      final dayItems = itemsByDay[day] ?? [];
      if (dayItems.isEmpty) {
        buffer.writeln(
          '   (Belum ada destinasi yang dijadwalkan untuk hari ini)',
        );
      } else {
        for (int i = 0; i < dayItems.length; i++) {
          final item = dayItems[i];
          final priceStr = item.ticketPrice <= 0
              ? 'Gratis'
              : _currencyFormatter.format(item.ticketPrice);
          buffer.writeln(
            '   ${i + 1}. ${item.destinationName} [${item.destinationCategory}]',
          );
          buffer.writeln('      • Tiket: $priceStr / orang');
          if (item.notes.isNotEmpty) {
            buffer.writeln('      • Catatan: ${item.notes}');
          }
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('========================================');
    buffer.writeln('🏔️ Disusun menggunakan BandungHub');
    buffer.writeln('✨ Smart Travel Companion & Itinerary Wisata Bandung');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  /// Menghasilkan format JSON yang terstruktur untuk backup atau import data antar pengguna
  static String generateJsonExport(Itinerary itinerary) {
    final map = Map<String, dynamic>.from(itinerary.toMap());
    map['items'] = itinerary.items.map((i) => i.toMap()).toList();
    map['export_source'] = 'BandungHub App';
    map['exported_at'] = DateTime.now().toIso8601String();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Menghasilkan dokumen HTML yang rapi & ramah cetak (print/PDF friendly)
  static String generateHtmlDocument(Itinerary itinerary) {
    final endDate = itinerary.startDate.add(
      Duration(days: itinerary.durationDays - 1),
    );
    final itemsByDay = itinerary.itemsByDay;

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="id">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <title>Itinerary: ${itinerary.title}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; margin: 30px; color: #2D3748; line-height: 1.5; }');
    buffer.writeln('    .header { border-bottom: 3px solid #00897B; padding-bottom: 12px; margin-bottom: 24px; }');
    buffer.writeln('    .title { color: #00897B; font-size: 26px; font-weight: bold; margin: 0; }');
    buffer.writeln('    .subtitle { color: #718096; font-size: 14px; margin-top: 4px; }');
    buffer.writeln('    .card { background: #F7FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 16px; margin-bottom: 20px; }');
    buffer.writeln('    .budget-table { width: 100%; border-collapse: collapse; margin-top: 10px; }');
    buffer.writeln('    .budget-table td, .budget-table th { padding: 8px 12px; border-bottom: 1px solid #E2E8F0; text-align: left; }');
    buffer.writeln('    .total-row { font-weight: bold; background: #E6FFFA; color: #00796B; }');
    buffer.writeln('    .day-header { background: #00897B; color: white; padding: 8px 14px; border-radius: 6px; margin-top: 24px; font-size: 16px; }');
    buffer.writeln('    .item-card { border-left: 4px solid #FF8F00; padding: 10px 14px; margin: 10px 0; background: #FFFDF9; }');
    buffer.writeln('    .footer { margin-top: 40px; text-align: center; color: #A0AEC0; font-size: 12px; border-top: 1px solid #E2E8F0; padding-top: 14px; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="header">');
    buffer.writeln('    <h1 class="title">BandungHub Travel Itinerary</h1>');
    buffer.writeln('    <div class="subtitle">${itinerary.title} • ${AppDateUtils.formatDate(itinerary.startDate)} s.d. ${AppDateUtils.formatDate(endDate)} (${itinerary.durationDays} Hari, ${itinerary.numberOfPeople} Orang)</div>');
    buffer.writeln('  </div>');

    // Ringkasan Anggaran
    buffer.writeln('  <div class="card">');
    buffer.writeln('    <h3 style="margin-top:0; color:#2D3748;">📊 Ringkasan Estimasi Anggaran</h3>');
    buffer.writeln('    <table class="budget-table">');
    buffer.writeln('      <tr><td>Tiket Destinasi</td><td><strong>${_currencyFormatter.format(itinerary.totalTicketCost)}</strong></td></tr>');
    buffer.writeln('      <tr><td>Transportasi</td><td><strong>${_currencyFormatter.format(itinerary.transportationCost)}</strong></td></tr>');
    buffer.writeln('      <tr><td>Kuliner & Konsumsi</td><td><strong>${_currencyFormatter.format(itinerary.foodCost)}</strong></td></tr>');
    if (itinerary.additionalCost > 0) {
      buffer.writeln('      <tr><td>Biaya Tambahan / Logistik</td><td><strong>${_currencyFormatter.format(itinerary.additionalCost)}</strong></td></tr>');
    }
    buffer.writeln(
      '      <tr class="total-row"><td>TOTAL ESTIMASI</td><td><strong>${_currencyFormatter.format(itinerary.totalEstimatedBudget)}</strong></td></tr>',
    );
    buffer.writeln('    </table>');
    buffer.writeln('  </div>');

    // Rencana Hari demi Hari
    for (int day = 1; day <= itinerary.durationDays; day++) {
      final dayDate = itinerary.startDate.add(Duration(days: day - 1));
      buffer.writeln('  <div class="day-header">📍 Hari $day — ${AppDateUtils.formatFullDate(dayDate)}</div>');

      final dayItems = itemsByDay[day] ?? [];
      if (dayItems.isEmpty) {
        buffer.writeln('  <p style="color:#718096; font-style:italic;">Belum ada kunjungan yang dijadwalkan.</p>');
      } else {
        for (int i = 0; i < dayItems.length; i++) {
          final item = dayItems[i];
          final priceStr = item.ticketPrice <= 0 ? 'Gratis' : _currencyFormatter.format(item.ticketPrice);
          buffer.writeln('  <div class="item-card">');
          buffer.writeln('    <strong>${i + 1}. ${item.destinationName}</strong> <span style="color:#718096; font-size:12px;">(${item.destinationCategory})</span>');
          buffer.writeln('    <div>Tiket: $priceStr</div>');
          if (item.notes.isNotEmpty) {
            buffer.writeln('    <div style="font-size:13px; color:#4A5568; margin-top:4px;">Catatan: ${item.notes}</div>');
          }
          buffer.writeln('  </div>');
        }
      }
    }

    if (itinerary.savedHash != null && itinerary.savedHash!.isNotEmpty) {
      buffer.writeln('  <div style="margin-top:20px; font-size:12px; color:#718096; font-family:monospace;">SHA-256 Integritas: ${itinerary.savedHash}</div>');
    }

    buffer.writeln('  <div class="footer">Dibuat dengan <strong>BandungHub</strong> — Smart Companion & Itinerary Wisata Bandung</div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Bagikan teks via sistem native Share Sheet
  static Future<void> shareItineraryText(Itinerary itinerary) async {
    final text = generatePlainText(itinerary);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Itinerary BandungHub: ${itinerary.title}',
        ),
      );
    } catch (_) {
      // Fallback to clipboard if native share sheet is unavailable (e.g. headless tests)
      await copyToClipboard(text);
    }
  }

  /// Salin teks itinerary ke Clipboard sistem
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
