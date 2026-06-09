import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// One docket scanned in the sector pickup session.
class SectorPickupScannedRow {
  const SectorPickupScannedRow({
    required this.docketNo,
    this.sealNo,
    this.pkgs,
  });

  final String docketNo;
  final String? sealNo;
  final String? pkgs;

  String get sessionKey => docketNo.trim().toLowerCase();

  SectorPickupScannedRow copyWith({
    String? sealNo,
    String? pkgs,
  }) {
    return SectorPickupScannedRow(
      docketNo: docketNo,
      sealNo: sealNo ?? this.sealNo,
      pkgs: pkgs ?? this.pkgs,
    );
  }
}

/// Manifested shipment not yet scanned (or marked exception).
class SectorPickupMissingRow {
  const SectorPickupMissingRow({
    required this.docketNo,
    this.sealNo,
    this.status = SectorPickupMissingStatus.missing,
    this.pkgs,
  });

  final String docketNo;
  final String? sealNo;
  final String status;
  final String? pkgs;

  String get sessionKey => docketNo.trim().toLowerCase();

  SectorPickupMissingRow copyWith({String? status, String? sealNo}) {
    return SectorPickupMissingRow(
      docketNo: docketNo,
      sealNo: sealNo ?? this.sealNo,
      status: status ?? this.status,
      pkgs: pkgs,
    );
  }
}

abstract final class SectorPickupMissingStatus {
  SectorPickupMissingStatus._();

  static const missing = 'Missing';
  static const notPicked = 'Not Picked';
  static const missed = 'Missed';
}

/// Expected shipment from linehaul / manifest details.
class SectorPickupExpectedShipment {
  const SectorPickupExpectedShipment({
    required this.docketNo,
    this.sealNo,
    this.pkgs,
  });

  final String docketNo;
  final String? sealNo;
  final String? pkgs;

  String get sessionKey => docketNo.trim().toLowerCase();

  SectorPickupMissingRow toMissingRow() {
    return SectorPickupMissingRow(
      docketNo: docketNo,
      sealNo: sealNo,
      pkgs: pkgs,
      status: SectorPickupMissingStatus.missing,
    );
  }

  factory SectorPickupExpectedShipment.fromJson(Map<String, dynamic> json) {
    final docket = OutboundDataParse.firstNonEmptyString(json, const [
          'docket_no',
          'docket_number',
          'shipment_id',
          'shipment_no',
          'consignment_no',
          'id',
        ]) ??
        '';
    return SectorPickupExpectedShipment(
      docketNo: docket,
      sealNo: OutboundDataParse.firstNonEmptyString(json, const [
        'seal_no',
        'bag_seal',
        'bag_code',
        'metal_seal',
      ]),
      pkgs: OutboundDataParse.firstNonEmptyString(json, const [
        'pkgs',
        'pcs',
        'number_of_parcel',
        'no_of_package',
      ]),
    );
  }

  factory SectorPickupExpectedShipment.fromPickupDetailShipment(
    Map<String, dynamic> json,
  ) {
    final docket = OutboundDataParse.firstNonEmptyString(json, const [
          'shipment_id',
          'docket_no',
        ]) ??
        '';
    return SectorPickupExpectedShipment(
      docketNo: docket,
      pkgs: '1',
    );
  }

  factory SectorPickupExpectedShipment.fromManifestShipment(
    ManifestShipmentRef shipment,
  ) {
    final docket = OutboundDataParse.firstNonEmptyString(
          shipment.toJson(),
          const ['id', 'shipment_invoice_no'],
        ) ??
        shipment.id ??
        shipment.shipmentInvoiceNo ??
        '';
    return SectorPickupExpectedShipment(
      docketNo: docket,
      sealNo: shipment.bagCode,
      pkgs: shipment.numberOfParcel ?? '1',
    );
  }

  static List<SectorPickupExpectedShipment> listFromLinehaulRaw(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) return const [];
    final raw = map['shipments'];
    if (raw is! List) return const [];
    final out = <SectorPickupExpectedShipment>[];
    for (final item in raw) {
      final row = OutboundDataParse.asStringKeyedMap(item);
      if (row == null) continue;
      final parsed = SectorPickupExpectedShipment.fromJson(row);
      if (parsed.docketNo.trim().isNotEmpty) out.add(parsed);
    }
    return out;
  }
}
