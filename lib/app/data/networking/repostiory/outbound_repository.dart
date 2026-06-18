import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_airline_option.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_branch_option.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/api_services.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';

/// Outbound Services V8 — all reads/writes over [ApiServices] with auth from [OutboundAuthContext].
class OutboundRepository {
  OutboundRepository({ApiServices? api}) : _api = api ?? ApiServices();

  final ApiServices _api;

  /// Last API error message after a failed call (empty on success paths).
  String lastMessage = '';

  void _clear() => lastMessage = '';

  void _setError(String message) => lastMessage = message;

  Future<
      ({
        String? token,
        String? userId,
        String? branchId,
        String? branchName,
        String hubBranchId,
      })> _auth() async {
    return OutboundAuthContext.load();
  }

  /// Branch / hub dropdown (hub scan, bagging, manifest). Path overridable at build:
  /// `--dart-define=OUTBOUND_BRANCH_LIST_PATH=getbranches`
  Future<List<OutboundBranchOption>> branchHubList() async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.getBranches(token: token);
    return r.when(
      success: OutboundBranchOption.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<List<OutboundAirlineOption>> airlineList() async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.getAirlines(token: token);
    return r.when(
      success: OutboundAirlineOption.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<APIResponse<dynamic>> _requireToken(
    Future<APIResponse> Function(String token) call,
  ) async {
    _clear();
    final ctx = await _auth();
    final token = ctx.token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final r = await call(token);
    r.when(
      success: (_) => _clear(),
      error: (e) => _setError(e.message),
    );
    return r;
  }

  Future<APIResponse<dynamic>> _requireTokenUser(
    Future<APIResponse> Function(String token, String userId) call,
  ) async {
    _clear();
    final ctx = await _auth();
    final token = ctx.token;
    final userId = ctx.userId;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      lastMessage = 'Auth incomplete';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final r = await call(token, userId);
    r.when(
      success: (_) => _clear(),
      error: (e) => _setError(e.message),
    );
    return r;
  }

  // --- Hub scan ---

  Future<APIResponse<dynamic>> hubScanSubmit({
    required String docketNo,
    required String branchId,
    required String status,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.hubScan(
        token: token,
        docketNo: docketNo.trim(),
        branchId: branchId.trim(),
        userId: userId,
        status: status,
      ),
    );
  }

  /// POST `hubScanFetchShipment` — populate docket details before save (`connote`).
  Future<APIResponse<HubScanFetchResult>> hubScanFetchShipment(
      String connote) async {
    final trimmed = connote.trim();
    final r = await _requireToken(
      (token) async {
        final api = await _api.hubScanFetchShipment(
          token: token,
          connote: trimmed,
        );
        return api.when(
          success: (data) {
            final parsed = HubScanFetchedShipment.parseResponse(data);
            if (parsed.isFailure) {
              final msg = parsed.serverMessage?.trim() ?? '';
              return APIResponse.error(
                AppException.errorWithMessage(
                  msg.isNotEmpty ? msg : 'Request failed',
                ),
              );
            }
            if (parsed.shipment == null) {
              final msg = parsed.serverMessage?.trim() ?? '';
              return APIResponse.error(
                AppException.errorWithMessage(
                  msg.isNotEmpty ? msg : 'Shipment not found',
                ),
              );
            }
            return APIResponse.success(parsed);
          },
          error: (e) => APIResponse.error(e),
        );
      },
    );
    return r.when(
      success: (data) => APIResponse.success(data as HubScanFetchResult),
      error: (e) => APIResponse.error(e),
    );
  }

  Future<APIResponse<List<HubScanLog>>> hubScanLogsResult({
    required String branchId,
    int limit = 50,
    int offset = 0,
  }) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final r = await _api.getHubScanLogs(
      token: token,
      branchId: branchId,
      limit: limit,
      offset: offset,
    );
    return r.when(
      success: (data) {
        final rows = HubScanLog.listFromDynamic(data);
        return APIResponse.success(rows);
      },
      error: (e) {
        lastMessage = e.message;
        return APIResponse.error(e);
      },
    );
  }

  /// Loads every hub scan log for [branchId] (batched; no UI filters).
  Future<APIResponse<List<HubScanLog>>> hubScanLogsFetchAll({
    required String branchId,
    int batchSize = 200,
    int maxRows = 5000,
  }) async {
    final all = <HubScanLog>[];
    final seenKeys = <String>{};
    var offset = 0;

    while (all.length < maxRows) {
      final r = await hubScanLogsResult(
        branchId: branchId,
        limit: batchSize,
        offset: offset,
      );
      final batch = r.when(
        success: (rows) => rows,
        error: (e) {
          if (all.isEmpty) {
            return null;
          }
          lastMessage = e.message;
          return <HubScanLog>[];
        },
      );
      if (batch == null) {
        return r.when(
          success: (_) => APIResponse.error(
            AppException.errorWithMessage(lastMessage),
          ),
          error: (e) => APIResponse.error(e),
        );
      }
      if (batch.isEmpty) break;

      var added = 0;
      for (final row in batch) {
        final key = _hubScanLogDedupeKey(row);
        if (seenKeys.add(key)) {
          all.add(row);
          added++;
        }
      }

      if (batch.length < batchSize) break;
      if (added == 0) break;
      offset += batch.length;
    }

    _sortHubScanLogsNewestFirst(all);
    return APIResponse.success(all);
  }

  /// Every branch — used when hub scan screen has no branch selected.
  Future<APIResponse<List<HubScanLog>>> hubScanLogsFetchAllBranches({
    required List<String> branchIds,
    int batchSize = 200,
    int maxRowsPerBranch = 5000,
  }) async {
    final ids =
        branchIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (ids.isEmpty) {
      lastMessage = 'No branches available';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }

    final all = <HubScanLog>[];
    final seenKeys = <String>{};
    var anySuccess = false;

    for (final branchId in ids) {
      final r = await hubScanLogsFetchAll(
        branchId: branchId,
        batchSize: batchSize,
        maxRows: maxRowsPerBranch,
      );
      r.when(
        success: (rows) {
          anySuccess = true;
          for (final row in rows) {
            final key = _hubScanLogDedupeKey(row);
            if (seenKeys.add(key)) all.add(row);
          }
        },
        error: (e) {
          if (!anySuccess && all.isEmpty) {
            lastMessage = e.message;
          }
        },
      );
    }

    if (!anySuccess && all.isEmpty) {
      return APIResponse.error(
        AppException.errorWithMessage(
          lastMessage.trim().isNotEmpty ? lastMessage : 'Request failed',
        ),
      );
    }

    _sortHubScanLogsNewestFirst(all);
    return APIResponse.success(all);
  }

  static void _sortHubScanLogsNewestFirst(List<HubScanLog> rows) {
    rows.sort((a, b) {
      final at = a.scannedAt ?? a.createdAt ?? '';
      final bt = b.scannedAt ?? b.createdAt ?? '';
      return bt.compareTo(at);
    });
  }

  static String _hubScanLogDedupeKey(HubScanLog row) {
    final id = row.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return '${row.shipmentId ?? ''}_${row.scannedAt ?? ''}_${row.shipmentInvoiceNo ?? ''}';
  }

  Future<List<HubScanLog>> hubScanLogs({
    required String branchId,
    int limit = 50,
  }) async {
    final r = await hubScanLogsResult(branchId: branchId, limit: limit);
    return r.when(
      success: (rows) => rows,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<List<ShipmentScanEvent>> shipmentScanHistory(String docketNo) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.getShipmentScanHistory(
      token: token,
      docketNo: docketNo.trim(),
    );
    return r.when(
      success: (data) {
        final rows = ShipmentScanEvent.listFromDynamic(data);
        rows.sort((a, b) {
          final ad = a.createdDate ?? '';
          final bd = b.createdDate ?? '';
          return bd.compareTo(ad);
        });
        return rows;
      },
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  /// Shipment master hint via existing `getShipmentByConsignmentId` (docket / consignment no).
  Future<APIResponse<dynamic>> shipmentByDocket(String docketNo) async {
    _clear();
    final ctx = await _auth();
    final token = ctx.token;
    final branchId = ctx.branchId;
    if (token == null ||
        token.isEmpty ||
        branchId == null ||
        branchId.isEmpty) {
      lastMessage = 'Auth incomplete';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final r = await _api.getConsignment(docketNo, branchId, token);
    r.when(
      success: (_) => _clear(),
      error: (e) => _setError(e.message),
    );
    return r;
  }

  // --- Bagging ---

  Future<APIResponse<dynamic>> createBag({
    required String originBranchId,
    required String destinationBranchId,
    required String metalSealNo,
    required String shipmentIdsCsv,
    String? bagCode,
  }) async {
    final shipmentIds = OutboundApiParams.parseShipmentIdsCsv(shipmentIdsCsv);
    final shipmentIdsField = OutboundApiParams.shipmentIdsCsv(shipmentIds);
    final r = await _requireTokenUser(
      (token, userId) => _api.createBag(
        token: token,
        originBranchId: originBranchId.trim(),
        destinationBranchId: destinationBranchId.trim(),
        metalSealNo: metalSealNo.trim(),
        userId: userId,
        shipmentIds: shipmentIdsField,
        bagCode: bagCode,
      ),
    );
    return r.when(
      success: (data) {
        final created = OutboundMutationResult.fromDynamic(data);
        return APIResponse.success(created.asMap ?? data);
      },
      error: (e) => APIResponse.error(e),
    );
  }

  Future<APIResponse<dynamic>> addShipmentToBag({
    required String bagId,
    required String docketNo,
    required String branchId,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.addShipmentToBag(
        token: token,
        bagCode: bagId.trim(),
        docketNo: docketNo.trim(),
        branchId: branchId.trim(),
        userId: userId,
      ),
    );
  }

  Future<BagDetail?> bagDetails(String bagId) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return null;
    }
    final r = await _fetchBagDetailsRaw(bagId);
    return r.when(
      success: BagDetail.fromDynamic,
      error: (e) {
        lastMessage = e.message;
        return null;
      },
    );
  }

  Future<APIResponse<dynamic>> _fetchBagDetailsRaw(String bagRef) async {
    final ref = bagRef.trim();
    return _requireToken(
      (token) => _api.getBagDetails(token: token, bagCode: ref),
    );
  }

  Future<APIResponse<dynamic>> fetchBagDetails(String bagId) =>
      _fetchBagDetailsRaw(bagId);

  Future<List<OutboundBagRow>> listBags({required String branchId}) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.listBags(token: token, branchId: branchId);
    return r.when(
      success: OutboundBagRow.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<APIResponse<dynamic>> removeShipmentFromBag({
    required String bagId,
    required String docketNo,
    required String branchId,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.removeShipmentFromBag(
        token: token,
        bagCode: bagId.trim(),
        docketNo: docketNo.trim(),
        branchId: branchId.trim(),
        userId: userId,
      ),
    );
  }

  Future<APIResponse<dynamic>> lockBag(String bagId) async {
    return _requireToken(
      (token) => _api.lockBag(token: token, bagCode: bagId.trim()),
    );
  }

  Future<APIResponse<dynamic>> rebagShipment({
    required String newBagId,
    required String docketNo,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.rebagShipment(
        token: token,
        newBagCode: newBagId.trim(),
        docketNo: docketNo.trim(),
        userId: userId,
      ),
    );
  }

  Future<APIResponse<dynamic>> baggingReport({
    required String bagCode,
    required String startDate,
    required String endDate,
  }) =>
      _requireToken(
        (token) => _api.baggingReport(
          token: token,
          bagCode: bagCode,
          startDate: startDate,
          endDate: endDate,
        ),
      );

  // --- Manifest ---

  Future<APIResponse<dynamic>> createManifest({
    required String bagIdsCommaSeparated,
    required String originBranchId,
    required String destinationBranchId,
  }) async {
    final r = await _requireTokenUser(
      (token, userId) => _api.createManifest(
        token: token,
        bagCodesCsv: bagIdsCommaSeparated.trim(),
        originBranchId: originBranchId.trim(),
        destinationBranchId: destinationBranchId.trim(),
        userId: userId,
      ),
    );
    return r.when(
      success: (data) {
        final created = OutboundMutationResult.fromDynamic(data);
        final ref = created.effectiveManifestRef;
        if (ref == null || ref.isEmpty) {
          final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim();
          return APIResponse.error(
            AppException.errorWithMessage(
              (msg != null && msg.isNotEmpty)
                  ? msg
                  : 'Manifest created but no manifest number returned.',
            ),
          );
        }
        return APIResponse.success(created.asMap ?? data);
      },
      error: (e) => APIResponse.error(e),
    );
  }

  Future<APIResponse<dynamic>> _fetchManifestDetailsRawRefs(
    Iterable<String?> manifestRefs,
  ) async {
    final refs = _uniqueNonEmpty(manifestRefs);
    if (refs.isEmpty) {
      return APIResponse.error(
        AppException.errorWithMessage('Manifest number is required'),
      );
    }
    return _requireToken((token) async {
      final variants = _manifestQueryVariants(refs);
      final r = await outboundFirstSuccessWhere(
        variants
            .map(
              (q) => () => _api.getManifestDetailsQuery(token: token, query: q),
            )
            .toList(),
        (data) => ManifestDetail.fromDynamic(data).hasContent,
      );
      return _manifestResponseOrError(r, 'Manifest details not found');
    });
  }

  Future<APIResponse<dynamic>> _fetchManifestDetailsRaw(String manifestRef) =>
      _fetchManifestDetailsRawRefs([manifestRef]);

  Future<ManifestDetail?> manifestDetails(String manifestId) async {
    final r = await _fetchManifestDetailsRaw(manifestId);
    return r.when(
      success: ManifestDetail.fromDynamic,
      error: (e) {
        lastMessage = e.message;
        return null;
      },
    );
  }

  Future<APIResponse<dynamic>> fetchManifestDetails(String manifestId) =>
      _fetchManifestDetailsRaw(manifestId);

  Future<APIResponse<dynamic>> fetchManifestDetailsByRefs(
    Iterable<String?> manifestRefs,
  ) =>
      _fetchManifestDetailsRawRefs(manifestRefs);

  Future<List<OutboundManifestRow>> listManifests({
    required String branchId,
  }) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.listManifests(token: token, branchId: branchId);
    return r.when(
      success: OutboundManifestRow.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<APIResponse<dynamic>> manifestReport({
    required String startDate,
    required String endDate,
    required String manifestNo,
  }) =>
      _requireToken(
        (token) => _api.manifestReport(
          token: token,
          startDate: startDate,
          endDate: endDate,
          manifestNo: manifestNo,
        ),
      );

  Future<APIResponse<dynamic>> printManifestData(String manifestId) async {
    return printManifestDataByRefs([manifestId]);
  }

  Future<APIResponse<dynamic>> printManifestDataByRefs(
    Iterable<String?> manifestRefs,
  ) async {
    final refs = _uniqueNonEmpty(manifestRefs);
    if (refs.isEmpty) {
      return APIResponse.error(
        AppException.errorWithMessage('Manifest number is required'),
      );
    }
    return _requireToken((token) async {
      final variants = _manifestQueryVariants(refs);
      final r = await outboundFirstSuccessWhere(
        variants
            .map(
              (q) => () => _api.printManifestDataQuery(token: token, query: q),
            )
            .toList(),
        (data) => ManifestDetail.fromDynamic(data).hasContent,
      );
      return _manifestResponseOrError(r, 'Print data not found');
    });
  }

  static List<String> _uniqueNonEmpty(Iterable<String?> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final value in values) {
      final ref = value?.trim();
      if (ref == null || ref.isEmpty) continue;
      if (!seen.add(ref)) continue;
      out.add(ref);
    }
    return out;
  }

  static List<Map<String, String>> _manifestQueryVariants(List<String> refs) {
    final seen = <String>{};
    final out = <Map<String, String>>[];
    for (final ref in refs) {
      for (final query in OutboundApiParams.manifestDetailQueries(ref)) {
        final key =
            query.entries.map((e) => '${e.key}=${e.value}').toList().join('&');
        if (seen.add(key)) out.add(query);
      }
    }
    return out;
  }

  static APIResponse<dynamic> _manifestResponseOrError(
    APIResponse<dynamic> response,
    String fallbackMessage,
  ) {
    return response.when(
      success: (data) {
        if (ManifestDetail.fromDynamic(data).hasContent) return response;
        final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim();
        return APIResponse.error(
          AppException.errorWithMessage(
            msg != null && msg.isNotEmpty ? msg : fallbackMessage,
          ),
        );
      },
      error: (_) => response,
    );
  }

  // --- Linehaul ---

  Future<APIResponse<dynamic>> assignLinehaul({
    required String manifestIdsCommaSeparated,
    required String vehicleNo,
    required String driverName,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.assignLinehaul(
        token: token,
        manifestIdsCommaSeparated: manifestIdsCommaSeparated.trim(),
        vehicleNo: vehicleNo.trim(),
        driverName: driverName.trim(),
        userId: userId,
      ),
    );
  }

  Future<List<OutboundLinehaulRow>> listLinehauls({
    String? status,
  }) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final filter = status?.trim();
    final r = await _api.listLinehauls(
      token: token,
      status: filter != null && filter.isNotEmpty ? filter : null,
    );
    return r.when(
      success: OutboundLinehaulRow.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<APIResponse<dynamic>> _fetchLinehaulDetailsRaw(
      String linehaulRef) async {
    final ref = linehaulRef.trim();
    return _requireToken((token) {
      final variants = OutboundApiParams.linehaulDetailQueries(ref);
      return outboundFirstSuccess(
        variants
            .map(
              (q) => () => _api.getLinehaulDetailsQuery(token: token, query: q),
            )
            .toList(),
      );
    });
  }

  Future<LinehaulDetail?> linehaulDetails(String linehaulId) async {
    final r = await _fetchLinehaulDetailsRaw(linehaulId);
    return r.when(
      success: LinehaulDetail.fromDynamic,
      error: (e) {
        lastMessage = e.message;
        return null;
      },
    );
  }

  Future<APIResponse<dynamic>> fetchLinehaulDetails(String linehaulId) =>
      _fetchLinehaulDetailsRaw(linehaulId);

  Future<APIResponse<dynamic>> updateLinehaulStatus({
    required String linehaulId,
    required String status,
    required String branchId,
  }) async {
    return _requireTokenUser(
      (token, userId) => _api.updateLinehaulStatus(
        token: token,
        linehaulRef: linehaulId.trim(),
        status: status.trim(),
        userId: userId,
        branchId: branchId.trim(),
      ),
    );
  }

  Future<APIResponse<dynamic>> linehaulReport({
    required String startDate,
    required String endDate,
  }) =>
      _requireToken(
        (token) => _api.linehaulReport(
          token: token,
          startDate: startDate,
          endDate: endDate,
        ),
      );

  Future<APIResponse<dynamic>> editLinehaul({
    required String linehaulId,
    String? vehicleNo,
    String? driverName,
    String? driverMobile,
    String? mawbNo,
    String? tripNo,
    String? departureTime,
    String? arrivalTime,
    String? remarks,
    String? flightNo,
    String? airline,
    String? ewayBill,
    String? transportType,
  }) =>
      _requireToken(
        (token) => _api.editLinehaul(
          token: token,
          body: OutboundApiParams.editLinehaulBody(
            linehaulId: linehaulId,
            vehicleNo: vehicleNo,
            driverName: driverName,
            driverMobile: driverMobile,
            mawbNo: mawbNo,
            tripNo: tripNo,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            remarks: remarks,
            flightNo: flightNo,
            airline: airline,
            ewayBill: ewayBill,
            transportType: transportType,
          ),
        ),
      );

  Future<APIResponse<dynamic>> deleteLinehaul({
    required String linehaulId,
    String? tripNo,
    String? mawbNo,
  }) =>
      _requireToken(
        (token) => _api.deleteLinehaul(
          token: token,
          linehaulId: linehaulId.trim(),
          tripNo: tripNo,
          mawbNo: mawbNo,
        ),
      );

  // --- Sector pickup ---

  Future<List<SectorPickupRow>> sectorPickupList() async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.getPickupListOutbound(token: token);
    return r.when(
      success: (data) {
        final rows = SectorPickupRow.listFromDynamic(data);
        final seen = <String>{};
        final unique = <SectorPickupRow>[];
        for (final row in rows) {
          final key = row.id?.trim();
          if (key == null || key.isEmpty) {
            unique.add(row);
            continue;
          }
          if (seen.add(key)) unique.add(row);
        }
        return unique;
      },
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<PickupDetail?> pickupDetail(String pickupId) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return null;
    }
    final r = await _api.getPickupDetail(
      token: token,
      pickupId: pickupId.trim(),
    );
    return r.when(
      success: PickupDetail.fromDynamic,
      error: (e) {
        lastMessage = e.message;
        return null;
      },
    );
  }

  Future<APIResponse<dynamic>> fetchPickupDetail(String pickupId) =>
      _requireToken(
        (token) => _api.getPickupDetail(
          token: token,
          pickupId: pickupId.trim(),
        ),
      );

  Future<APIResponse<dynamic>> _treatBenignPickupDuplicate(
    Future<APIResponse<dynamic>> Function() call,
  ) async {
    final r = await call();
    return r.when(
      success: (data) => APIResponse.success(data),
      error: (e) {
        if (outboundIsBenignDuplicate(e.message)) {
          return APIResponse.success({
            'status': 'success',
            'message': e.message,
            'data': {},
          });
        }
        return APIResponse.error(e);
      },
    );
  }

  Future<APIResponse<dynamic>> sectorPickupScan({
    required String pickupId,
    required String docketNo,
    required String status,
    required String remarks,
    required String branchId,
  }) {
    return _treatBenignPickupDuplicate(
      () => _requireTokenUser(
        (token, userId) => _api.sectorPickupScan(
          token: token,
          pickupId: pickupId.trim(),
          docketNo: docketNo.trim(),
          status: status.trim(),
          remarks: remarks.trim(),
          userId: userId,
          branchId: branchId.trim(),
        ),
      ),
    );
  }

  Future<APIResponse<dynamic>> markNotPicked({
    required String pickupId,
    required String docketNo,
    required String remarks,
    required String branchId,
  }) {
    return _treatBenignPickupDuplicate(
      () => _requireTokenUser(
        (token, userId) => _api.markNotPicked(
          token: token,
          pickupId: pickupId.trim(),
          docketNo: docketNo.trim(),
          remarks: remarks.trim(),
          userId: userId,
          branchId: branchId.trim(),
        ),
      ),
    );
  }

  Future<APIResponse<dynamic>> addMissedShipment({
    required String pickupId,
    required String docketNo,
    required String remarks,
    required String branchId,
  }) {
    return _requireTokenUser(
      (token, userId) => _api.addMissedShipment(
        token: token,
        pickupId: pickupId.trim(),
        docketNo: docketNo.trim(),
        remarks: remarks.trim(),
        userId: userId,
        branchId: branchId.trim(),
      ),
    );
  }

  Future<APIResponse<dynamic>> pickupReport({
    required String startDate,
    required String endDate,
  }) =>
      _requireToken(
        (token) => _api.pickupReportOutbound(
          token: token,
          startDate: startDate,
          endDate: endDate,
        ),
      );
}
