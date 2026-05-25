import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pocket_noc/core/models/diagnostic_result.dart';

class PdfExportService {
  static Future<File?> exportResults({
    required List<DiagnosticResult> results,
    required String title,
    String? targetHost,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(title, targetHost),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          ...results.map((r) => _buildResultSection(r)),
        ],
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/pocket_noc_report_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<void> exportAndShare({
    required List<DiagnosticResult> results,
    required String title,
    String? targetHost,
  }) async {
    final file = await exportResults(
      results: results,
      title: title,
      targetHost: targetHost,
    );
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Pocket NOC Report - $title',
      );
    }
  }

  static pw.Widget _buildHeader(String title, String? targetHost) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Pocket NOC',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(title,
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey600)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                DateTime.now().toIso8601String().substring(0, 19),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
              if (targetHost != null)
                pw.Text('Target: $targetHost',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey500)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  static pw.Widget _buildResultSection(DiagnosticResult result) {
    final statusColor =
        result.success ? PdfColors.green700 : PdfColors.red700;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: statusColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '${result.type.toUpperCase()} - ${result.target}',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Spacer(),
              if (result.durationMs > 0)
                pw.Text('${result.durationMs}ms',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(result.summary,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          if (result.data.isNotEmpty)
            ...result.data.entries.take(15).map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 120,
                        child: pw.Text(e.key,
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '${e.value}',
                          style: const pw.TextStyle(fontSize: 9),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                )),
          if (result.error != null) ...[
            pw.SizedBox(height: 4),
            pw.Text('Error: ${result.error}',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            result.timestamp.toIso8601String().substring(0, 19),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
