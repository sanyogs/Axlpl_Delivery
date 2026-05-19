import 'package:flutter/foundation.dart';

/// QA shipment/bag/manifest ids for debug runs and emulator testing.
///
/// Override at build time, e.g.:
/// `--dart-define=OUTBOUND_TEST_DOCKET=990831778839479`
///
/// When a define is empty and [kDebugMode] is true, the defaults below are used.
class OutboundTestIds {
  OutboundTestIds._();

  static const String _docketEnv =
      String.fromEnvironment('OUTBOUND_TEST_DOCKET');
  static const String _bagCodeEnv =
      String.fromEnvironment('OUTBOUND_TEST_BAG_CODE');
  static const String _manifestEnv =
      String.fromEnvironment('OUTBOUND_TEST_MANIFEST_ID');
  static const String _mawbEnv = String.fromEnvironment('OUTBOUND_TEST_MAWB');
  static const String _pickupEnv =
      String.fromEnvironment('OUTBOUND_TEST_PICKUP_ID');
  static const String _branchEnv =
      String.fromEnvironment('OUTBOUND_TEST_BRANCH_ID');
  static const String _baggingDocketEnv =
      String.fromEnvironment('OUTBOUND_TEST_BAGGING_DOCKET');
  static const String _listBagsBranchEnv =
      String.fromEnvironment('OUTBOUND_TEST_LIST_BAGS_BRANCH_ID');

  static const String _removeDocketEnv =
      String.fromEnvironment('OUTBOUND_TEST_REMOVE_DOCKET');
  static const String _manifestOriginEnv =
      String.fromEnvironment('OUTBOUND_TEST_MANIFEST_ORIGIN_BRANCH');
  static const String _manifestDestEnv =
      String.fromEnvironment('OUTBOUND_TEST_MANIFEST_DEST_BRANCH');

  static const String _debugDocket = '558751776258671';
  static const String _debugBaggingDocket = '825411779084407';
  static const String _debugRemoveDocket = '442291776257551';
  static const String _debugBranchId = '73';
  static const String _debugListBagsBranchId = '75';
  static const String _debugManifestOriginBranch = '37';
  static const String _debugManifestDestBranch = '75';
  static const String _debugBagCode = 'BAG20260518152744831';
  static const String _debugManifest = 'MUM094';
  static const String _debugMawb = 'mum4321';
  static const String _debugPickup = '122';

  /// QA defaults are opt-in via `--dart-define` only (never auto-filled in UI).
  static bool get useDebugDefaults => false;

  static String get docket =>
      _pick(_docketEnv, useDebugDefaults ? _debugDocket : '');

  /// Bagging screen shipment no (different from hub-scan docket).
  static String get baggingDocket =>
      _pick(_baggingDocketEnv, useDebugDefaults ? _debugBaggingDocket : '');

  /// Remove / rebag docket (Sarvesh QA).
  static String get removeDocket =>
      _pick(_removeDocketEnv, useDebugDefaults ? _debugRemoveDocket : '');

  static String get bagCode =>
      _pick(_bagCodeEnv, useDebugDefaults ? _debugBagCode : '');

  static String get manifestId =>
      _pick(_manifestEnv, useDebugDefaults ? _debugManifest : '');

  static String get mawbNo => _pick(_mawbEnv, useDebugDefaults ? _debugMawb : '');

  static String get pickupId =>
      _pick(_pickupEnv, useDebugDefaults ? _debugPickup : '');

  /// Hub scan / logs branch.
  static String get branchId =>
      _pick(_branchEnv, useDebugDefaults ? _debugBranchId : '');

  /// `listbags` origin depot (Sarvesh QA: branch 75).
  static String get listBagsBranchId => _pick(
        _listBagsBranchEnv,
        useDebugDefaults ? _debugListBagsBranchId : '',
      );

  static String get manifestOriginBranchId => _pick(
        _manifestOriginEnv,
        useDebugDefaults ? _debugManifestOriginBranch : '',
      );

  static String get manifestDestBranchId => _pick(
        _manifestDestEnv,
        useDebugDefaults ? _debugManifestDestBranch : '',
      );

  static bool get hasAny =>
      docket.isNotEmpty ||
      baggingDocket.isNotEmpty ||
      removeDocket.isNotEmpty ||
      bagCode.isNotEmpty ||
      manifestId.isNotEmpty ||
      pickupId.isNotEmpty ||
      branchId.isNotEmpty ||
      listBagsBranchId.isNotEmpty ||
      manifestOriginBranchId.isNotEmpty;

  static String _pick(String env, String debugFallback) {
    if (env.trim().isNotEmpty) return env.trim();
    return debugFallback.trim();
  }
}
