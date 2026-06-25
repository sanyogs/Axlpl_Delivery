import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';

/// Bag-level row for linehaul pre-alert **Consignment Details** table.
class LinehaulConsignmentSummary {
  const LinehaulConsignmentSummary({
    required this.slNo,
    this.masterBag,
    this.bagNo,
    this.entryNo,
    this.destHub,
    this.consignmentCount = 0,
    this.boxCount = 0,
    this.productMode,
    this.weight,
    this.shipmentType,
  });

  final int slNo;
  final String? masterBag;
  final String? bagNo;
  final String? entryNo;
  final String? destHub;
  final int consignmentCount;
  final int boxCount;
  final String? productMode;
  final String? weight;
  final String? shipmentType;

  static List<LinehaulConsignmentSummary> build({
    required List<ManifestBagRef> bags,
    required List<ManifestShipmentRef> shipments,
    String? defaultDestHub,
  }) {
    if (bags.isNotEmpty) {
      return [
        for (var i = 0; i < bags.length; i++)
          _fromBag(
            slNo: i + 1,
            bag: bags[i],
            shipments: shipments,
            defaultDestHub: defaultDestHub,
          ),
      ];
    }

    final groups = <String, List<ManifestShipmentRef>>{};
    for (final shipment in shipments) {
      final key = shipment.bagCode?.trim().isNotEmpty == true
          ? shipment.bagCode!.trim()
          : (shipment.bagId?.trim().isNotEmpty == true
              ? shipment.bagId!.trim()
              : '—');
      groups.putIfAbsent(key, () => []).add(shipment);
    }

    if (groups.isEmpty) return const [];

    return [
      for (final entry in groups.entries.toList().asMap().entries)
        _fromShipments(
          slNo: entry.key + 1,
          bagKey: entry.value.key,
          shipments: entry.value.value,
          defaultDestHub: defaultDestHub,
        ),
    ];
  }

  static LinehaulConsignmentSummary _fromBag({
    required int slNo,
    required ManifestBagRef bag,
    required List<ManifestShipmentRef> shipments,
    String? defaultDestHub,
  }) {
    final bagShipments = shipments.where((s) {
      final bagId = bag.id?.trim();
      final bagCode = bag.bagCode?.trim();
      if (bagId != null &&
          bagId.isNotEmpty &&
          s.bagId?.trim() == bagId) {
        return true;
      }
      if (bagCode != null &&
          bagCode.isNotEmpty &&
          s.bagCode?.trim() == bagCode) {
        return true;
      }
      return false;
    }).toList();

    return _fromShipments(
      slNo: slNo,
      bagKey: bag.bagCode ?? bag.id ?? '—',
      shipments: bagShipments,
      defaultDestHub: defaultDestHub,
      masterBag: bag.masterBag ?? bag.metalSealNo ?? bag.id,
      bagWeight: bag.grossWeight,
    );
  }

  static LinehaulConsignmentSummary _fromShipments({
    required int slNo,
    required String bagKey,
    required List<ManifestShipmentRef> shipments,
    String? defaultDestHub,
    String? masterBag,
    String? bagWeight,
  }) {
    var boxes = 0;
    var weight = 0.0;
    String? destHub;
    String? productMode;
    String? shipmentType;
    String? entryNo;

    for (final shipment in shipments) {
      final pcs = int.tryParse(shipment.numberOfParcel ?? '') ?? 0;
      boxes += pcs > 0 ? pcs : 1;
      weight += double.tryParse(shipment.grossWeight ?? '') ??
          double.tryParse(shipment.netWeight ?? '') ??
          0;
      destHub ??= shipment.destinationCity?.trim().isNotEmpty == true
          ? shipment.destinationCity
          : null;
      productMode ??= shipment.productMode?.trim().isNotEmpty == true
          ? shipment.productMode
          : null;
      shipmentType ??= shipment.paymentMode?.trim().isNotEmpty == true
          ? shipment.paymentMode
          : null;
      entryNo ??= shipment.entryNo?.trim().isNotEmpty == true
          ? shipment.entryNo
          : null;
    }

    final resolvedWeight = bagWeight?.trim().isNotEmpty == true
        ? bagWeight!.trim()
        : (weight > 0 ? _formatWeight(weight) : '—');

    return LinehaulConsignmentSummary(
      slNo: slNo,
      masterBag: masterBag,
      bagNo: bagKey == '—' ? null : bagKey,
      entryNo: entryNo,
      destHub: destHub ?? defaultDestHub,
      consignmentCount: shipments.isEmpty ? 0 : shipments.length,
      boxCount: boxes,
      productMode: productMode ?? 'NORMAL',
      weight: resolvedWeight,
      shipmentType: shipmentType,
    );
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
