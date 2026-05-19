import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:get/get.dart';

/// Applies default depot selection after [OutboundBranchListController] loads.
Future<void> outboundApplyDepotDefaults({
  required void Function(String?) setOrigin,
  required void Function(String?) setDestination,
  void Function(String?)? setListBranch,
  bool sameDestAsOrigin = false,
  String? preferredOriginId,
}) async {
  final branchList = Get.find<OutboundBranchListController>();
  if (branchList.branches.isEmpty && !branchList.isLoadingBranches.value) {
    await branchList.loadBranches();
  }
  final ctx = await OutboundAuthContext.load();
  final preferred = preferredOriginId?.trim().isNotEmpty == true
      ? preferredOriginId!.trim()
      : OutboundAuthContext.branchIdForLists(ctx.branchId);
  String? pick(String? current) {
    if (current != null && current.isNotEmpty) return current;
    if (branchList.branches.any((b) => b.id == preferred)) return preferred;
    return branchList.branches.isNotEmpty ? branchList.branches.first.id : null;
  }

  final origin = pick(null);
  setOrigin(origin);
  setDestination(sameDestAsOrigin ? origin : pick(null));
  if (setListBranch != null) {
    setListBranch(pick(null));
  }
}
