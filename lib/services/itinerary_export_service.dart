import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/utils/date_utils.dart';
import '../models/itinerary.dart';

/// Service untuk membagikan rencana perjalanan (Itinerary)
/// Mendukung 2 format pilihan utama: Catatan Teks (WhatsApp/Notes) dan Dokumen PDF Resmi.
class ItineraryExportService {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Menghasilkan format catatan teks rapi untuk WhatsApp, Telegram, Email, atau aplikasi Catatan.
  static String generatePlainText(Itinerary itinerary) {
    final buffer = StringBuffer();
    final endDate = itinerary.startDate.add(
      Duration(days: itinerary.durationDays - 1),
    );

    buffer.writeln('========================================');
    buffer.writeln('🎒 CATATAN RENCANA PERJALANAN');
    buffer.writeln('📌 ${itinerary.title.toUpperCase()}');
    buffer.writeln('========================================');
    buffer.writeln(
      '📅 Periode     : ${AppDateUtils.formatDate(itinerary.startDate)} s.d. ${AppDateUtils.formatDate(endDate)} (${itinerary.durationDays} Hari)',
    );
    buffer.writeln('👥 Jumlah Tamu : ${itinerary.numberOfPeople} Orang');
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

    buffer.writeln('🗺️ JADWAL PERJALANAN:');
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
    buffer.writeln('Disusun via BandungHub - Panduan Wisata Bandung');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  /// Menghasilkan file PDF terstruktur rapi (A4) dengan rincian jadwal dan biaya.
  static Future<Uint8List> generatePdfBytes(Itinerary itinerary) async {
    final pdf = pw.Document(
      title: 'Rencana Perjalanan ${itinerary.title} - BandungHub',
      author: 'BandungHub App',
    );

    final endDate = itinerary.startDate.add(
      Duration(days: itinerary.durationDays - 1),
    );
    final itemsByDay = itinerary.itemsByDay;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.teal, width: 2.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RENCANA PERJALANAN WISATA - BANDUNGHUB',
                        style: pw.TextStyle(
                          color: PdfColors.teal,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        itinerary.title,
                        style: pw.TextStyle(
                          color: PdfColors.grey900,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${itinerary.durationDays} Hari (${itinerary.numberOfPeople} Tamu)',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Metadata card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Periode Perjalanan:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        '${AppDateUtils.formatDate(itinerary.startDate)} s.d. ${AppDateUtils.formatDate(endDate)}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Destinasi:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        '${itinerary.items.length} Tempat Wisata',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Estimasi Anggaran:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        _currencyFormatter.format(itinerary.totalEstimatedBudget),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Budget summary table
            pw.Text(
              'Rincian Estimasi Biaya',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Komponen Biaya', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Estimasi', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Tiket Masuk Wisata', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currencyFormatter.format(itinerary.totalTicketCost), style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Transportasi', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currencyFormatter.format(itinerary.transportationCost), style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Kuliner & Makan', style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currencyFormatter.format(itinerary.foodCost), style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
                if (itinerary.additionalCost > 0)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Biaya Tambahan / Logistik', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(_currencyFormatter.format(itinerary.additionalCost), style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('TOTAL ESTIMASI', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_currencyFormatter.format(itinerary.totalEstimatedBudget), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // Daily Schedule
            pw.Text(
              'Rencana Perjalanan Harian',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            for (int day = 1; day <= itinerary.durationDays; day++) ...[
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Hari $day: ${AppDateUtils.formatFullDate(itinerary.startDate.add(Duration(days: day - 1)))}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if ((itemsByDay[day] ?? []).isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: pw.Text(
                    'Belum ada jadwal kunjungan untuk hari ini.',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                )
              else
                for (int i = 0; i < (itemsByDay[day] ?? []).length; i++) ...[
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 3),
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${i + 1}. ${(itemsByDay[day]!)[i].destinationName}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              (itemsByDay[day]!)[i].destinationCategory,
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tiket: ${(itemsByDay[day]!)[i].ticketPrice <= 0 ? "Gratis" : _currencyFormatter.format((itemsByDay[day]!)[i].ticketPrice)} / orang',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                        ),
                        if ((itemsByDay[day]!)[i].notes.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Catatan: ${(itemsByDay[day]!)[i].notes}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
            ],
            pw.SizedBox(height: 24),

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(
                'Dibuat dengan BandungHub - Smart Travel Companion & Panduan Wisata Bandung',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Membagikan dokumen PDF via sistem native Share Sheet
  static Future<void> shareItineraryPdf(Itinerary itinerary) async {
    final pdfBytes = await generatePdfBytes(itinerary);
    try {
      final safeTitle = itinerary.title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/Itinerary_${safeTitle}_BandungHub.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'application/pdf',
              name: 'Itinerary_${safeTitle}_BandungHub.pdf',
            ),
          ],
          subject: 'Itinerary PDF: ${itinerary.title}',
          text: 'Berikut adalah dokumen PDF itinerary "${itinerary.title}" dari aplikasi BandungHub.',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Bagikan catatan teks via sistem native Share Sheet
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
      // Fallback ke clipboard jika native share sheet tidak tersedia
      await copyToClipboard(text);
    }
  }

  /// Salin teks itinerary ke Clipboard sistem
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Menghasilkan format JSON cadangan (jika diperlukan untuk import internal)
  static String generateJsonExport(Itinerary itinerary) {
    final map = Map<String, dynamic>.from(itinerary.toMap());
    map['items'] = itinerary.items.map((i) => i.toMap()).toList();
    map['export_source'] = 'BandungHub App';
    map['exported_at'] = DateTime.now().toIso8601String();
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
