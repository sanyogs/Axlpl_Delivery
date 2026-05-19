import 'package:axlpl_delivery/app/data/models/outbound/outbound_branch_option.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:get/get.dart';

/// Loads branch / hub options for outbound screens (hub scan, bagging, manifest).
class OutboundBranchListController extends GetxController {
  OutboundBranchListController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final branches = <OutboundBranchOption>[].obs;
  final selectedBranchId = RxnString();
  final isLoadingBranches = false.obs;
  final branchListMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBranches();
  }

  String? get selectedBranchIdOrNull => selectedBranchId.value?.trim().isNotEmpty == true
      ? selectedBranchId.value!.trim()
      : null;

  OutboundBranchOption? optionForId(String? id) {
    if (id == null || id.isEmpty) return null;
    final key = id.trim();
    for (final b in branches) {
      if (b.id == key) return b;
    }
    return null;
  }

  /// Human-readable branch / sector label for detail screens (name, else id).
  String displayLabelForId(String? id) {
    if (id == null || id.trim().isEmpty) return '—';
    final key = id.trim();
    final opt = optionForId(key);
    if (opt != null) {
      final label = opt.label.trim();
      if (label.isNotEmpty) return label;
    }
    return key;
  }

  Future<void> loadBranches() async {
    isLoadingBranches.value = true;
    branchListMessage.value = '';
    try {
      final rows = await _repo.branchHubList();
      if (rows.isNotEmpty) {
        branches.assignAll(rows);
        branchListMessage.value = '';
      } else {
        branches.assignAll(await _fallbackBranches());
        if (_repo.lastMessage.isNotEmpty) {
          branchListMessage.value = _repo.lastMessage;
        }
      }
      await _applyDefaultSelection();
    } finally {
      isLoadingBranches.value = false;
    }
  }

  Future<List<OutboundBranchOption>> _fallbackBranches() async {
    final ctx = await OutboundAuthContext.load();
    final out = <OutboundBranchOption>[];
    void add(OutboundBranchOption? o) {
      if (o == null) return;
      if (out.any((e) => e.id == o.id)) return;
      out.add(o);
    }

    add(OutboundBranchOption.fromMessenger(
      branchId: ctx.branchId,
      branchName: ctx.branchName,
    ));
    add(OutboundBranchOption(
      id: ctx.hubBranchId,
      label: 'Hub ${ctx.hubBranchId}',
    ));
    return out;
  }

  Future<void> _applyDefaultSelection() async {
    if (branches.isEmpty) {
      selectedBranchId.value = null;
      return;
    }
    // No auto-selection — user picks branch from dropdown.
    final current = selectedBranchId.value?.trim();
    if (current != null &&
        current.isNotEmpty &&
        branches.any((b) => b.id == current)) {
      return;
    }
    selectedBranchId.value = null;
  }

  void onBranchSelected(String? branchId) {
    selectedBranchId.value = branchId;
  }

  void showLoadIssueIfNeeded() {
    if (branchListMessage.value.isEmpty) return;
    Get.snackbar(
      'Branch / Hub',
      branchListMessage.value,
      duration: const Duration(seconds: 4),
    );
  }
}
