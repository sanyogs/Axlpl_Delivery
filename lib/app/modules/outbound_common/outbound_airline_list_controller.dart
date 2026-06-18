import 'package:axlpl_delivery/app/data/models/outbound/outbound_airline_option.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:get/get.dart';

/// Loads airlines for linehaul booking / edit.
class OutboundAirlineListController extends GetxController {
  OutboundAirlineListController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final airlines = <OutboundAirlineOption>[].obs;
  final isLoadingAirlines = false.obs;
  final airlineListMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAirlines();
  }

  Future<void> loadAirlines() async {
    isLoadingAirlines.value = true;
    airlineListMessage.value = '';
    try {
      final rows = await _repo.airlineList();
      airlines.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        airlineListMessage.value = _repo.lastMessage;
        showLoadIssueIfNeeded();
      }
    } finally {
      isLoadingAirlines.value = false;
    }
  }

  OutboundAirlineOption? optionForId(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return null;
    for (final a in airlines) {
      if (a.id == key) return a;
    }
    return null;
  }

  String? resolveId(String? value) {
    final key = value?.trim();
    if (key == null || key.isEmpty) return null;
    for (final a in airlines) {
      if (a.id == key) return a.id;
      if (a.name.toLowerCase() == key.toLowerCase()) return a.id;
      if (a.code?.toLowerCase() == key.toLowerCase()) return a.id;
      if (a.label.toLowerCase() == key.toLowerCase()) return a.id;
    }
    return key;
  }

  String displayLabelForId(String? id) {
    final key = id?.trim();
    if (key == null || key.isEmpty) return '—';
    final opt = optionForId(key);
    if (opt != null) return opt.label;
    for (final a in airlines) {
      if (a.name.toLowerCase() == key.toLowerCase()) return a.label;
      if (a.code?.toLowerCase() == key.toLowerCase()) return a.label;
    }
    return key;
  }

  void showLoadIssueIfNeeded() {
    if (airlineListMessage.value.isEmpty) return;
    Get.snackbar(
      'Airline',
      airlineListMessage.value,
      duration: const Duration(seconds: 4),
    );
  }
}
