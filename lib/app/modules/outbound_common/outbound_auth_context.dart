import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';

/// Resolves auth fields for outbound V8 calls (messenger-first).
class OutboundAuthContext {
  OutboundAuthContext._();

  /// Branch used for hub scan logs / bag lists when messenger home branch has no rows.
  /// Override at build time: `--dart-define=OUTBOUND_HUB_BRANCH_ID=27`
  static const String hubDataBranchId = String.fromEnvironment(
    'OUTBOUND_HUB_BRANCH_ID',
    defaultValue: '27',
  );

  static Future<
      ({
        String? token,
        String? userId,
        String? branchId,
        String hubBranchId,
      })> load() async {
    final user = await LocalStorage().getUserLocalData();
    final m = user?.messangerdetail;
    final token = m?.token ?? user?.customerdetail?.token;
    final messengerBranch = m?.branchId?.trim();
    return (
      token: token,
      userId: m?.id,
      branchId: messengerBranch,
      hubBranchId: hubDataBranchId,
    );
  }

  /// Branch for POST bodies that require [branch_id] (hub scan, bagging scan).
  static String branchIdForScan(String? messengerBranchId) {
    final m = messengerBranchId?.trim();
    if (m != null && m.isNotEmpty) return m;
    return hubDataBranchId;
  }

  /// Branch for list endpoints (bags/manifests) — prefer hub data branch.
  static String branchIdForLists(String? messengerBranchId) {
    final m = messengerBranchId?.trim();
    if (m != null && m.isNotEmpty && m != '2') return m;
    return hubDataBranchId;
  }
}
