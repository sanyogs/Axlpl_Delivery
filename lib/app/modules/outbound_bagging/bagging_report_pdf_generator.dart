import 'dart:io';

import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the admin **Bagging Challan / Report** PDF (matches web print layout).
class BaggingReportPdfGenerator {
  BaggingReportPdfGenerator._();

  static const _gstn = '27AAQCA4042D1ZU';
  static const _website = 'www.axlpl.com';
  static const _email = 'info@axlpl.com';

  static String formatPrintDate(DateTime when) =>
      DateFormat('dd-MMM-yyyy HH:mm a').format(when);

  static pw.Document buildDocument({
    required BaggingReport report,
    required String createdByDisplay,
    DateTime? printDate,
  }) {
    final printedAt = printDate ?? DateTime.now();
    final items = report.items;
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'GSTN: $_gstn | Website: $_website | Email: $_email',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'BAGGING CHALLAN / REPORT',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          _headerGrid([
            _HeaderCell('Bagging Number:', report.bagCode ?? '—'),
            _HeaderCell('Metal Seal No:', report.metalSealNo ?? '—'),
            _HeaderCell(
              'Origin Depot:',
              report.originBranchName ?? report.originBranchId ?? '—',
            ),
            _HeaderCell(
              'Destination:',
              report.destinationCityName ?? report.destinationSectorId ?? '—',
            ),
            _HeaderCell('Created By:', createdByDisplay),
            _HeaderCell('Print Date:', formatPrintDate(printedAt)),
          ]),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FlexColumnWidth(2.2),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(2.2),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FixedColumnWidth(44),
              6: const pw.FixedColumnWidth(36),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('Sr.', bold: true),
                  _cell('Shipment ID', bold: true),
                  _cell('Sender Name', bold: true),
                  _cell('Receiver Name', bold: true),
                  _cell('Destination', bold: true),
                  _cell('WT', bold: true, align: pw.TextAlign.right),
                  _cell('PCS', bold: true, align: pw.TextAlign.right),
                ],
              ),
              for (var i = 0; i < items.length; i++)
                pw.TableRow(
                  children: [
                    _cell('${i + 1}'),
                    _cell(_formatShipmentId(items[i].shipmentId)),
                    _cell(items[i].senderName ?? '—'),
                    _cell(items[i].receiverName ?? '—'),
                    _cell(items[i].destinationCity ?? '—'),
                    _cell(
                      items[i].weightDisplay,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      items[i].pcsDisplay,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              pw.TableRow(
                children: [
                  _cell(''),
                  _cell('Total:', bold: true),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(
                    report.totalWeightDisplay,
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    report.totalPcsDisplay,
                    bold: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 36),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Prepared By Signature'),
              _signatureBlock('Authorized Signatory'),
            ],
          ),
        ],
      ),
    );

    return doc;
  }

  /// Writes PDF to app documents and returns the file path.
  static Future<String> save({
    required BaggingReport report,
    required String createdByDisplay,
    DateTime? printDate,
  }) async {
    final doc = buildDocument(
      report: report,
      createdByDisplay: createdByDisplay,
      printDate: printDate,
    );
    final bytes = await doc.save();
    final bagRef = (report.bagCode ?? report.metalSealNo ?? 'bagging')
        .replaceAll(RegExp(r'[^\w.-]+'), '_');
    final fileName = 'Bagging Print - $bagRef.pdf';

    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ??
          await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _formatShipmentId(String? id) {
    final s = id?.trim();
    if (s == null || s.isEmpty) return '—';
    return s.startsWith('#') ? s : '#$s';
  }

  static pw.Widget _headerGrid(List<_HeaderCell> cells) {
    return pw.Column(
      children: [
        for (var i = 0; i < cells.length; i += 2)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _headerPair(cells[i])),
                if (i + 1 < cells.length)
                  pw.Expanded(child: _headerPair(cells[i + 1]))
                else
                  pw.Expanded(child: pw.SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _headerPair(_HeaderCell cell) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '${cell.label} ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.TextSpan(text: cell.value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _signatureBlock(String label) {
    return pw.SizedBox(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

class _HeaderCell {
  const _HeaderCell(this.label, this.value);
  final String label;
  final String value;
}
