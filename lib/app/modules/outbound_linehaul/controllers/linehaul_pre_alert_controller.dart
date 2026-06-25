import 'package:axlpl_delivery/app/data/models/outbound/linehaul_consignment_summary_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_airline_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/linehaul_pre_alert_pdf_generator.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

/// Loads and prints linehaul pre-alert (`getlinehauldetails` + manifest enrichment).
class LinehaulPreAlertController extends GetxController {
  LinehaulPreAlertController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final detail = Rxn<LinehaulDetail>();
  final shipments = <ManifestShipmentRef>[].obs;
  final bags = <ManifestBagRef>[].obs;
  final isLoading = false.obs;
  final isPrinting = false.obs;
  final errorMessage = ''.obs;

  String? _linehaulRef;

  List<LinehaulConsignmentSummary> get consignmentRows {
    final d = detail.value;
    if (d == null) return const [];
    return LinehaulConsignmentSummary.build(
      bags: bags.toList(growable: false),
      shipments: shipments.toList(growable: false),
      defaultDestHub: _destinationHubLabel(d),
    );
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _linehaulRef = args['ref']?.toString().trim();
    }
    load();
  }

  @override
  void onClose() {
    detail.value = null;
    shipments.clear();
    bags.clear();
    errorMessage.value = '';
    super.onClose();
  }

  Future<bool> load({String? ref}) async {
    final lookup = ref?.trim() ?? _linehaulRef?.trim();
    if (lookup == null || lookup.isEmpty) {
      errorMessage.value = 'Linehaul reference is required.';
      return false;
    }
    _linehaulRef = lookup;
    isLoading.value = true;
    errorMessage.value = '';
    detail.value = null;
    shipments.clear();
    bags.clear();

    try {
      final r = await _repo.fetchLinehaulDetails(lookup);
      var ok = false;
      await r.when(
        success: (data) async {
          final parsed = LinehaulDetail.fromDynamic(data);
          if (parsed.detailLookupRef == null && parsed.linehaulId == null) {
            errorMessage.value =
                OutboundUiFeedback.serverMessageFromData(data)?.trim() ??
                    'Linehaul details not found.';
            return;
          }
          detail.value = parsed;
          final enriched = await _enrichFromManifests(parsed);
          shipments.assignAll(enriched.shipments);
          bags.assignAll(enriched.bags);
          ok = true;
        },
        error: (e) {
          errorMessage.value = e.message;
        },
      );
      return ok;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> printPreAlert() async {
    final d = detail.value;
    if (d == null || isPrinting.value) return;

    isPrinting.value = true;
    try {
      final path = await LinehaulPreAlertPdfGenerator.save(
        detail: d,
        shipments: shipments.toList(growable: false),
        consignments: consignmentRows,
        originHub: _originHubLabel(d),
        destinationHub: _destinationHubLabel(d),
        vendor: _vendorLabel(d),
        flightDate: _flightDateLabel(d),
      );
      final open = await OpenFile.open(path);
      if (open.type != ResultType.done) {
        Get.snackbar('Linehaul', 'PDF saved: $path');
        return;
      }
      Get.snackbar('Linehaul', 'Pre-alert PDF generated.');
    } finally {
      isPrinting.value = false;
    }
  }

  String originHubLabel() {
    final d = detail.value;
    if (d == null) return '—';
    return _originHubLabel(d);
  }

  String destinationHubLabel() {
    final d = detail.value;
    if (d == null) return '—';
    return _destinationHubLabel(d);
  }

  String vendorLabel() {
    final d = detail.value;
    if (d == null) return '—';
    return _vendorLabel(d);
  }

  String flightDateLabel() {
    final d = detail.value;
    if (d == null) return '—';
    return _flightDateLabel(d);
  }

  String _originHubLabel(LinehaulDetail d) => _hubLabel(
        apiName: d.originBranchName,
        id: d.origin,
      );

  String _destinationHubLabel(LinehaulDetail d) => _hubLabel(
        apiName: d.destinationBranchName,
        id: d.destination,
      );

  String _hubLabel({String? apiName, String? id}) {
    final name = apiName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (Get.isRegistered<OutboundBranchListController>()) {
      return Get.find<OutboundBranchListController>().displayLabelForId(id);
    }
    return id?.trim().isNotEmpty == true ? id!.trim() : '—';
  }

  String _vendorLabel(LinehaulDetail d) {
    final airline = d.airline?.trim();
    if (airline != null && airline.isNotEmpty) {
      if (Get.isRegistered<OutboundAirlineListController>()) {
        return Get.find<OutboundAirlineListController>()
            .displayLabelForId(airline);
      }
      return airline;
    }
    return '—';
  }

  String _flightDateLabel(LinehaulDetail d) {
    final explicit = d.flightDate?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return _formatAdminDate(explicit);
    }
    final departure = d.departureTime?.trim();
    if (departure == null || departure.isEmpty) return '—';
    final parts = departure.split(' ');
    return _formatAdminDate(parts.first);
  }

  String _formatAdminDate(String raw) {
    final value = raw.trim();
    final parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return '${parsed.day.toString().padLeft(2, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.year}';
    }
    return value;
  }

  Future<({List<ManifestShipmentRef> shipments, List<ManifestBagRef> bags})>
      _enrichFromManifests(LinehaulDetail parsed) async {
    final mergedShipments = <String, ManifestShipmentRef>{};
    for (final shipment in parsed.shipments) {
      final key = _shipmentKey(shipment);
      if (key.isNotEmpty) mergedShipments[key] = shipment;
    }

    final mergedBags = <String, ManifestBagRef>{};
    for (final bag in parsed.bags) {
      final key = bag.bagCode?.trim().isNotEmpty == true
          ? bag.bagCode!.trim()
          : bag.id?.trim();
      if (key != null && key.isNotEmpty) mergedBags[key] = bag;
    }

    final needsEnrichment = mergedShipments.isEmpty ||
        mergedShipments.values.every(_shipmentNeedsEnrichment);

    if (needsEnrichment || parsed.manifests.isNotEmpty) {
      for (final manifest in parsed.manifests) {
        final code = manifest.manifestNo?.trim().isNotEmpty == true
            ? manifest.manifestNo!.trim()
            : manifest.id?.trim();
        if (code == null || code.isEmpty) continue;

        final mr = await _repo.fetchManifestDetailsByRefs([code]);
        mr.when(
          success: (manifestData) {
            final md = ManifestDetail.fromDynamic(manifestData);
            for (final bag in md.bags) {
              final key = bag.bagCode?.trim().isNotEmpty == true
                  ? bag.bagCode!.trim()
                  : bag.id?.trim();
              if (key != null && key.isNotEmpty) mergedBags[key] = bag;
            }
            for (final shipment in md.shipments) {
              final key = _shipmentKey(shipment);
              if (key.isEmpty) continue;
              final existing = mergedShipments[key];
              mergedShipments[key] =
                  existing == null || _shipmentNeedsEnrichment(existing)
                      ? shipment
                      : existing;
            }
          },
          error: (_) {},
        );
      }
    }

    return (
      shipments: mergedShipments.values.toList(growable: false),
      bags: mergedBags.values.toList(growable: false),
    );
  }

  bool _shipmentNeedsEnrichment(ManifestShipmentRef shipment) {
    final sender = shipment.senderName?.trim();
    final receiver = shipment.receiverName?.trim();
    return (sender == null || sender.isEmpty) &&
        (receiver == null || receiver.isEmpty);
  }

  String _shipmentKey(ManifestShipmentRef shipment) {
    final id = shipment.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    final invoice = shipment.shipmentInvoiceNo?.trim();
    if (invoice != null && invoice.isNotEmpty) return invoice;
    return '';
  }
}
