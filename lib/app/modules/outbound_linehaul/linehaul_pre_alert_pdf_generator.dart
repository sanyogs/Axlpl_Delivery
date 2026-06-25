import 'dart:io';

import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_consignment_summary_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds the admin **Linehaul Pre-Alert** PDF.
class LinehaulPreAlertPdfGenerator {
  LinehaulPreAlertPdfGenerator._();

  static pw.Document buildDocument({
    required LinehaulDetail detail,
    required List<ManifestShipmentRef> shipments,
    required List<LinehaulConsignmentSummary> consignments,
    required String originHub,
    required String destinationHub,
    required String vendor,
    required String flightDate,
    DateTime? printDate,
  }) {
    final printedAt = printDate ?? DateTime.now();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
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
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'LINEHAUL PRE-ALERT',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Print Date: ${BaggingReportPdfGenerator.formatPrintDate(printedAt)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('PRE-ALERT DETAILS'),
          pw.SizedBox(height: 6),
          _detailsGrid([
            _DetailCell('Origin', originHub),
            _DetailCell('Destination', destinationHub),
            _DetailCell('MAWB NO', detail.mawbNo ?? detail.airwayBillNo ?? '—'),
            _DetailCell('Flight No & Mode', detail.flightNoAndMode),
            _DetailCell('Flight Date', flightDate),
            _DetailCell('Vendor', vendor),
            _DetailCell('STD', detail.stdFromDeparture ?? '—'),
            _DetailCell('STA', detail.arrivalTime ?? '—'),
            _DetailCell('No Of Bags', detail.noOfBags ?? detail.noOfBoxes ?? '—'),
            _DetailCell(
              'Total No of Cons',
              '${detail.totalConsignments}',
            ),
            _DetailCell('Total No of Boxes', detail.noOfBoxes ?? '—'),
            _DetailCell('Total Weight (Kgs)', detail.totalWeight ?? '—'),
          ]),
          pw.SizedBox(height: 14),
          _sectionTitle('CONSIGNMENT DETAILS'),
          pw.SizedBox(height: 6),
          _consignmentTable(consignments),
          pw.SizedBox(height: 14),
          _sectionTitle('DOCKET DETAILS'),
          pw.SizedBox(height: 6),
          _docketTable(shipments),
        ],
      ),
    );

    return doc;
  }

  static Future<String> save({
    required LinehaulDetail detail,
    required List<ManifestShipmentRef> shipments,
    required List<LinehaulConsignmentSummary> consignments,
    required String originHub,
    required String destinationHub,
    required String vendor,
    required String flightDate,
    DateTime? printDate,
  }) async {
    final doc = buildDocument(
      detail: detail,
      shipments: shipments,
      consignments: consignments,
      originHub: originHub,
      destinationHub: destinationHub,
      vendor: vendor,
      flightDate: flightDate,
      printDate: printDate,
    );
    final bytes = await doc.save();
    final mawb = (detail.mawbNo ?? detail.airwayBillNo ?? 'linehaul')
        .replaceAll(RegExp(r'[^\w.-]+'), '_');
    final fileName = 'Linehaul Pre-Alert - $mawb.pdf';

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

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      color: PdfColors.blue800,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _detailsGrid(List<_DetailCell> cells) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        for (var i = 0; i < cells.length; i += 2)
          pw.TableRow(
            children: [
              _labelCell(cells[i].label),
              _valueCell(cells[i].value),
              if (i + 1 < cells.length) ...[
                _labelCell(cells[i + 1].label),
                _valueCell(cells[i + 1].value),
              ] else ...[
                _labelCell(''),
                _valueCell(''),
              ],
            ],
          ),
      ],
    );
  }

  static pw.Widget _consignmentTable(List<LinehaulConsignmentSummary> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(20),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(0.7),
        6: pw.FlexColumnWidth(0.7),
        7: pw.FlexColumnWidth(0.8),
        8: pw.FlexColumnWidth(0.7),
        9: pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('SL', bold: true),
            _cell('Master Bag', bold: true),
            _cell('Bag No', bold: true),
            _cell('Entry No', bold: true),
            _cell('Dest Hub', bold: true),
            _cell('Consign', bold: true),
            _cell('Boxes', bold: true),
            _cell('Mode', bold: true),
            _cell('Weight', bold: true),
            _cell('Type', bold: true),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            children: [
              _cell('${row.slNo}'),
              _cell(row.masterBag ?? '—'),
              _cell(row.bagNo ?? '—'),
              _cell(row.entryNo ?? '—'),
              _cell(row.destHub ?? '—'),
              _cell('${row.consignmentCount}'),
              _cell('${row.boxCount}'),
              _cell(row.productMode ?? '—'),
              _cell(row.weight ?? '—'),
              _cell(row.shipmentType ?? '—'),
            ],
          ),
        if (rows.isEmpty)
          pw.TableRow(
            children: List.generate(10, (_) => _cell('—')),
          ),
      ],
    );
  }

  static pw.Widget _docketTable(List<ManifestShipmentRef> shipments) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FixedColumnWidth(28),
        4: pw.FixedColumnWidth(52),
        5: pw.FixedColumnWidth(52),
        6: pw.FixedColumnWidth(48),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('DOCKET NO', bold: true),
            _cell('SENDER', bold: true),
            _cell('RECEIVER', bold: true),
            _cell('PCS', bold: true),
            _cell('NET WT', bold: true),
            _cell('GROSS WT', bold: true),
            _cell('PAID', bold: true),
          ],
        ),
        for (final shipment in shipments)
          pw.TableRow(
            children: [
              _cell(shipment.docketNo),
              _cell(shipment.senderName ?? '—'),
              _cell(shipment.receiverName ?? '—'),
              _cell(shipment.pcsDisplay),
              _cell(shipment.netWeightDisplay),
              _cell(shipment.grossWeightDisplay),
              _cell(shipment.paidDisplay),
            ],
          ),
        if (shipments.isEmpty)
          pw.TableRow(
            children: List.generate(7, (_) => _cell('—')),
          ),
      ],
    );
  }

  static pw.Widget _labelCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _valueCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
    );
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

class _DetailCell {
  const _DetailCell(this.label, this.value);
  final String label;
  final String value;
}
