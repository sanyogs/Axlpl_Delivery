import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_branch_option.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/api_services.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_validation.dart';
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

  Map<String, String> _bagPostBody(String bagRef, Map<String, String> base) {
    final refFields = OutboundApiParams.bagReferenceBody(bagRef);
    return {...base, ...refFields};
  }

  // --- Hub scan ---

  Future<APIResponse<dynamic>> hubScanSubmit({
    required String docketNo,
    required String branchId,
    required String status,
  }) async {
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      lastMessage = docketErr;
      return APIResponse.error(AppException.errorWithMessage(docketErr));
    }
    if (branchId.trim().isEmpty) {
      lastMessage = 'Branch id is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
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

  Future<List<HubScanLog>> hubScanLogs({
    required String branchId,
    int limit = 50,
  }) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.getHubScanLogs(
      token: token,
      branchId: branchId,
      limit: limit,
    );
    return r.when(
      success: HubScanLog.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<List<ShipmentScanEvent>> shipmentScanHistory(String docketNo) async {
    _clear();
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      lastMessage = docketErr;
      return [];
    }
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
    required String bagCode,
    String? metalSealNo,
    required String shipmentIdsCsv,
  }) async {
    if (originBranchId.trim().isEmpty || destinationBranchId.trim().isEmpty) {
      lastMessage = 'Origin and destination branch are required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final code = bagCode.trim();
    final seal = (metalSealNo ?? bagCode).trim();
    if (code.isEmpty || seal.isEmpty) {
      lastMessage = 'Metal seal / bag code is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final shipmentIds = OutboundApiParams.parseShipmentIdsCsv(shipmentIdsCsv);
    if (shipmentIds.isEmpty) {
      lastMessage =
          'At least one shipment id is required for bagging (docket no)';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    final shipmentIdsField = OutboundApiParams.shipmentIdsCsv(shipmentIds);
    final r = await _requireTokenUser(
      (token, userId) => _api.createBag(
        token: token,
        originBranchId: originBranchId.trim(),
        destinationBranchId: destinationBranchId.trim(),
        bagCode: code,
        metalSealNo: seal,
        userId: userId,
        shipmentIds: shipmentIdsField,
      ),
    );
    return r.when(
      success: (data) {
        final err = OutboundValidation.validateCreateBagPayload(data);
        if (err != null) {
          lastMessage = err;
          return APIResponse.error(AppException.errorWithMessage(err));
        }
        final created = OutboundMutationResult.fromDynamic(data);
        final ref = created.effectiveBagRef;
        if (ref != null && ref.isNotEmpty) {
          return APIResponse.success({
            ...?created.asMap,
            'bag_id': ref,
            'bag_code': created.bagCode ?? ref,
          });
        }
        return APIResponse.success(data);
      },
      error: (e) => APIResponse.error(e),
    );
  }

  Future<APIResponse<dynamic>> addShipmentToBag({
    required String bagId,
    required String docketNo,
    required String branchId,
  }) async {
    final bagErr = OutboundValidation.validateBagId(bagId);
    if (bagErr != null) {
      lastMessage = bagErr;
      return APIResponse.error(AppException.errorWithMessage(bagErr));
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      lastMessage = docketErr;
      return APIResponse.error(AppException.errorWithMessage(docketErr));
    }
    if (branchId.trim().isEmpty) {
      lastMessage = 'Branch id is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
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
    final bagErr = OutboundValidation.validateBagId(bagId);
    if (bagErr != null) {
      lastMessage = bagErr;
      return null;
    }
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
    final bagErr = OutboundValidation.validateBagId(bagRef);
    if (bagErr != null) {
      lastMessage = bagErr;
      return APIResponse.error(AppException.errorWithMessage(bagErr));
    }
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
    final bagErr = OutboundValidation.validateBagId(bagId);
    if (bagErr != null) {
      lastMessage = bagErr;
      return APIResponse.error(AppException.errorWithMessage(bagErr));
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      lastMessage = docketErr;
      return APIResponse.error(AppException.errorWithMessage(docketErr));
    }
    if (branchId.trim().isEmpty) {
      lastMessage = 'Branch id is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
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
    final bagErr = OutboundValidation.validateBagId(bagId);
    if (bagErr != null) {
      lastMessage = bagErr;
      return APIResponse.error(AppException.errorWithMessage(bagErr));
    }
    return _requireToken(
      (token) => _api.lockBag(token: token, bagCode: bagId.trim()),
    );
  }

  Future<APIResponse<dynamic>> rebagShipment({
    required String newBagId,
    required String docketNo,
  }) async {
    final bagErr = OutboundValidation.validateBagId(newBagId);
    if (bagErr != null) {
      lastMessage = bagErr;
      return APIResponse.error(AppException.errorWithMessage(bagErr));
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      lastMessage = docketErr;
      return APIResponse.error(AppException.errorWithMessage(docketErr));
    }
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
    required String startDate,
    required String endDate,
    String? bagCode,
  }) =>
      _requireToken(
        (token) => _api.baggingReport(
          token: token,
          startDate: startDate,
          endDate: endDate,
          bagCode: bagCode,
        ),
      );

  // --- Manifest ---

  Future<APIResponse<dynamic>> createManifest({
    required String bagIdsCommaSeparated,
    required String originBranchId,
    required String destinationBranchId,
  }) async {
    if (bagIdsCommaSeparated.trim().isEmpty) {
      lastMessage = 'At least one bag id is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    for (final part in bagIdsCommaSeparated.split(',')) {
      final bagErr = OutboundValidation.validateBagId(part);
      if (bagErr != null) {
        lastMessage = bagErr;
        return APIResponse.error(AppException.errorWithMessage(bagErr));
      }
    }
    return _requireTokenUser(
      (token, userId) => _api.createManifest(
        token: token,
        bagCodesCsv: bagIdsCommaSeparated.trim(),
        originBranchId: originBranchId.trim(),
        destinationBranchId: destinationBranchId.trim(),
        userId: userId,
      ),
    );
  }

  Future<APIResponse<dynamic>> _fetchManifestDetailsRaw(String manifestRef) async {
    final err = OutboundValidation.validateManifestId(manifestRef);
    if (err != null) {
      lastMessage = err;
      return APIResponse.error(AppException.errorWithMessage(err));
    }
    final ref = manifestRef.trim();
    return _requireToken((token) {
      final variants = OutboundApiParams.manifestDetailQueries(ref);
      return outboundFirstSuccess(
        variants
            .map(
              (q) => () => _api.getManifestDetailsQuery(token: token, query: q),
            )
            .toList(),
      );
    });
  }

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
    String? manifestNo,
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
    final err = OutboundValidation.validateManifestId(manifestId);
    if (err != null) {
      lastMessage = err;
      return APIResponse.error(AppException.errorWithMessage(err));
    }
    final ref = manifestId.trim();
    return _requireToken((token) {
      final variants = OutboundApiParams.manifestDetailQueries(ref);
      return outboundFirstSuccess(
        variants
            .map(
              (q) => () => _api.printManifestDataQuery(token: token, query: q),
            )
            .toList(),
      );
    });
  }

  // --- Linehaul ---

  Future<APIResponse<dynamic>> assignLinehaul({
    required String manifestIdsCommaSeparated,
    required String vehicleNo,
    required String driverName,
  }) async {
    if (manifestIdsCommaSeparated.trim().isEmpty) {
      lastMessage = 'Manifest id(s) required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
    if (vehicleNo.trim().isEmpty || driverName.trim().isEmpty) {
      lastMessage = 'Vehicle and driver name are required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
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
    required String status,
  }) async {
    _clear();
    final token = (await _auth()).token;
    if (token == null || token.isEmpty) {
      lastMessage = 'Not logged in';
      return [];
    }
    final r = await _api.listLinehauls(token: token, status: status);
    return r.when(
      success: OutboundLinehaulRow.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

  Future<APIResponse<dynamic>> _fetchLinehaulDetailsRaw(String linehaulRef) async {
    final err = OutboundValidation.validateLinehaulId(linehaulRef);
    if (err != null) {
      lastMessage = err;
      return APIResponse.error(AppException.errorWithMessage(err));
    }
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
    final lhErr = OutboundValidation.validateLinehaulId(linehaulId);
    if (lhErr != null) {
      lastMessage = lhErr;
      return APIResponse.error(AppException.errorWithMessage(lhErr));
    }
    if (status.trim().isEmpty) {
      lastMessage = 'Linehaul status is required';
      return APIResponse.error(AppException.errorWithMessage(lastMessage));
    }
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
      success: SectorPickupRow.listFromDynamic,
      error: (e) {
        lastMessage = e.message;
        return [];
      },
    );
  }

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
    final pickupErr = _validatePickupId(pickupId);
    if (pickupErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(pickupErr)),
      );
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(docketErr)),
      );
    }
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
    final pickupErr = _validatePickupId(pickupId);
    if (pickupErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(pickupErr)),
      );
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(docketErr)),
      );
    }
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
    final pickupErr = _validatePickupId(pickupId);
    if (pickupErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(pickupErr)),
      );
    }
    final docketErr = OutboundValidation.validateDocket(docketNo);
    if (docketErr != null) {
      return Future.value(
        APIResponse.error(AppException.errorWithMessage(docketErr)),
      );
    }
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

  String? _validatePickupId(String? pickupId) {
    final s = pickupId?.trim() ?? '';
    if (s.isEmpty) return 'Pickup id is required';
    return null;
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
