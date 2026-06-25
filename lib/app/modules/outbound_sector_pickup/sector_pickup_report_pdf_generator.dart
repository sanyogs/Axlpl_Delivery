import 'dart:io';

import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the admin **Sector Pickup Report** PDF from `getpickupdetail`.
class SectorPickupReportPdfGenerator {
  SectorPickupReportPdfGenerator._();

  static pw.Document buildDocument({
    required PickupDetail detail,
    DateTime? printDate,
  }) {
    final printedAt = printDate ?? DateTime.now();
    final bagGroups = SectorPickupReportBagGroup.fromPickupDetail(detail);
    final doc = pw.Document();
    final pickupId = detail.id?.trim().isNotEmpty == true
        ? detail.id!.trim()
        : '—';
    final pickedBy = detail.pickedBy?.trim().isNotEmpty == true
        ? detail.pickedBy!.trim()
        : 'N/A';
    final createdAt = detail.createdAt?.trim().isNotEmpty == true
        ? detail.createdAt!.trim()
        : '—';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  BaggingReport.companyName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '...One Step Ahead',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'SECTOR PICKUP REPORT',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Transaction ID- SGP $pickupId',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400),
                bottom: pw.BorderSide(color: PdfColors.grey400),
              ),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaLine('MAWB No.', detail.mawbNo ?? '—'),
                      _metaLine('Picked By', pickedBy),
                      _metaLine(
                        'Total Manifested',
                        '${detail.manifestedCount} Shipments',
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _metaLine('Hub Branch', detail.hubBranchLabel),
                      _metaLine('Pickup Date', detail.pickupDateTimeLabel),
                      _metaLine('Created At', createdAt),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Pickup Details (Received Shipments)',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          _pickupTable(bagGroups),
          pw.SizedBox(height: 16),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey500,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Report Generated On: '
                  '${BaggingReportPdfGenerator.formatPrintDate(printedAt)}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'This is a computer generated document.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static Future<String> save({
    required PickupDetail detail,
    DateTime? printDate,
  }) async {
    final doc = buildDocument(detail: detail, printDate: printDate);
    final bytes = await doc.save();
    final id = (detail.id ?? 'pickup').replaceAll(RegExp(r'[^\w.-]+'), '_');
    final fileName = 'Sector Pickup Report - SGP $id.pdf';

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

  static pw.Widget _metaLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pickupTable(List<SectorPickupReportBagGroup> groups) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FixedColumnWidth(40),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('SL', bold: true),
            _cell('Bag code & Code', bold: true),
            _cell('Dest Hub', bold: true),
            _cell('Shipments / Packages', bold: true),
            _cell('Packets', bold: true),
          ],
        ),
        for (final group in groups) ...[
          pw.TableRow(
            children: [
              _cell('${group.slNo}'),
              _cell(group.bagLabel),
              _cell(group.destHub),
              _cell('${group.shipmentCount} Shipments'),
              _cell('${group.packetCount}'),
            ],
          ),
          for (final shipment in group.shipments)
            pw.TableRow(
              children: [
                _cell(''),
                _cell(
                  '- ${shipment.docketNo} (${shipment.displayCodeSuffix})',
                ),
                _cell(
                  group.isLooseGroup
                      ? shipment.destHubDisplay
                      : shipment.destHubDisplay,
                ),
                _cell('1'),
                _cell(shipment.packetsDisplay),
              ],
            ),
        ],
        if (groups.isEmpty)
          pw.TableRow(
            children: List.generate(5, (_) => _cell('—')),
          ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
