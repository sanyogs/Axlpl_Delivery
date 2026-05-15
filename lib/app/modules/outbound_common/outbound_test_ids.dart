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

  static const String _debugDocket = '990831778839479';
  static const String _debugBagCode = 'BAG20260515154014';
  static const String _debugManifest = 'MUM075';
  static const String _debugMawb = 'mum4321';
  static const String _debugPickup = '122';

  static bool get useDebugDefaults => kDebugMode;

  static String get docket =>
      _pick(_docketEnv, useDebugDefaults ? _debugDocket : '');

  static String get bagCode =>
      _pick(_bagCodeEnv, useDebugDefaults ? _debugBagCode : '');

  static String get manifestId =>
      _pick(_manifestEnv, useDebugDefaults ? _debugManifest : '');

  static String get mawbNo => _pick(_mawbEnv, useDebugDefaults ? _debugMawb : '');

  static String get pickupId =>
      _pick(_pickupEnv, useDebugDefaults ? _debugPickup : '');

  static bool get hasAny =>
      docket.isNotEmpty ||
      bagCode.isNotEmpty ||
      manifestId.isNotEmpty ||
      pickupId.isNotEmpty;

  static String _pick(String env, String debugFallback) {
    if (env.trim().isNotEmpty) return env.trim();
    return debugFallback.trim();
  }
}
