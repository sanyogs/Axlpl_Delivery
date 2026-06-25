import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/sector_pickup_report_pdf_generator.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

/// Loads `getpickupdetail` and prints the admin sector pickup report PDF.
class SectorPickupReportShowController extends GetxController {
  SectorPickupReportShowController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final detail = Rxn<PickupDetail>();
  final isLoading = false.obs;
  final isPrinting = false.obs;
  final errorMessage = ''.obs;

  String? _pickupId;

  List<SectorPickupReportBagGroup> get bagGroups {
    final d = detail.value;
    if (d == null) return const [];
    return SectorPickupReportBagGroup.fromPickupDetail(d);
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _pickupId = args.trim();
    } else if (args is Map) {
      _pickupId = args['pickup_id']?.toString().trim() ??
          args['id']?.toString().trim();
    }
    load();
  }

  Future<bool> load({String? pickupId}) async {
    final id = pickupId?.trim() ?? _pickupId?.trim();
    if (id == null || id.isEmpty) {
      errorMessage.value = 'Pickup id is required.';
      return false;
    }
    _pickupId = id;
    isLoading.value = true;
    errorMessage.value = '';
    detail.value = null;

    try {
      final parsed = await _repo.pickupDetail(id);
      if (parsed == null) {
        errorMessage.value = _repo.lastMessage.trim().isNotEmpty
            ? _repo.lastMessage.trim()
            : 'Pickup details not found.';
        return false;
      }
      detail.value = parsed;
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> printReport() async {
    final d = detail.value;
    if (d == null || isPrinting.value) return;

    isPrinting.value = true;
    try {
      final path = await SectorPickupReportPdfGenerator.save(detail: d);
      final open = await OpenFile.open(path);
      if (open.type != ResultType.done) {
        Get.snackbar('Sector pickup', 'PDF saved: $path');
        return;
      }
      Get.snackbar('Sector pickup', 'Sector pickup report PDF generated.');
    } finally {
      isPrinting.value = false;
    }
  }
}
