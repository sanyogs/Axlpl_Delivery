import 'dart:convert';
import 'dart:developer';

import 'package:axlpl_delivery/app/data/models/shipment_req_static_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_client.dart';
import 'package:axlpl_delivery/app/data/networking/api_endpoint.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:dio/dio.dart';

import "dart:async";
import 'api_response.dart';

const _sendOtpEndpoint = 'user/send-otp';
const _verifyOtpEndpoint = 'user/verify-otp';

class ApiServices {
  static final ApiClient _api = ApiClient();

  Future<APIResponse> sendOtpService(String mobile) async {
    final data = {'mobile': mobile};
    return _api.post(
      _sendOtpEndpoint,
      data,
      contentType: ContentType.json,
    );
  }

  Future<APIResponse> verifyOtpService(
    String mobile,
    String otp,
    String fcmToken,
    String appVersion,
    String latitude,
    String longitude,
    String deviceId,
  ) async {
    final data = {
      'mobile': mobile,
      'otp': otp,
      'fcm_token': fcmToken,
      'app_version': appVersion,
      'latitude': latitude,
      'longitude': longitude,
      'device_id': deviceId,
    };
    return _api.post(
      _verifyOtpEndpoint,
      data,
      contentType: ContentType.json,
    );
  }

  Future<APIResponse> getConsignment(
    String consigenmentID,
    final branchID,
    final token,
    // String zipcode,
  ) async {
    final body = {
      'consignment_no': consigenmentID,
      'branch_id': branchID
      // 'zipcode': zipcode,
    };
    return _api.get(
      getConsignmentPoint,
      query: body,
      token: token,
    );
  }

  Future<APIResponse> getDeliveryHistory(
    String userID,
    String zipcode,
    String branchID,
    String nextID,
    String token,
  ) async {
    final query = {
      'messanger_id': userID,
      'zipcode': zipcode,
      'branch_id': branchID,
      'next_id': nextID
    };
    return _api.get(
      deliveryHistoryPoint,
      query: query,
      token: token,
    );
  }

  Future<APIResponse> getPickupHistory(
    String userID,
    String branchID,
    // String zipcode,
    // String paymentMode,
    String token,
  ) async {
    final body = {
      'messanger_id': userID,
      // 'zipcode': zipcode,
      'branch_id': branchID
    };
    return _api.get(
      historyPickupPoint,
      query: body,
      token: token,
    );
  }

  Future<APIResponse> getDashboardData(
    String userID,
    String branchID,
    // String zipcode,
    String token,
  ) async {
    final query = {
      'messanger_id': userID,
      'branch_id': branchID,
    };
    return _api.get(
      dashboardDataPoint,
      query: query,
      token: token,
    );
  }

  Future<APIResponse> getCustomerDashboardData(
    String custID,

    // String zipcode,
    String token,
  ) async {
    final body = {
      'customer_id': custID,
    };
    return _api.post(
      customerDashboardDataPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getCustomersList(
    String userID,
    String branchID,
    String? search,
    String nextID,
    String token,
  ) async {
    final query = {
      'm_id': userID,
      'branch_id': branchID,
      'search_query': search ?? "",
      'next_id': nextID
    };
    return _api.get(getCustomersListPoint, query: query, token: token);
  }

  Future<APIResponse> getCategoryList(
    String? search,
    String token,
  ) async {
    final query = {
      'search_query': search ?? "",
    };
    return _api.get(getCategoryListPoint, query: query, token: token);
  }

  Future<APIResponse> getAllDelivery(
    final id,
    final brachID,
    final nextID,
    final token,
  ) {
    final body = {
      'messanger_id': id,
      'branch_id': brachID,
      'next_id': nextID,
      'token': token,
    };
    return _api.post(
      getAllDeliveryPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getCommodityList(
    String? search,
    String? categoryID,
    String token,
  ) async {
    final body = {
      'search_query': search ?? "",
      'category_id': categoryID,
    };
    return _api.post(
      getCommodityListPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getServiceTypeList(
    String token,
  ) async {
    final body = {};
    return _api.post(getServiceTypePoint, body, token: token);
  }

  Future<APIResponse> getPincodeDetails(String token, String pincode) async {
    final body = {
      'pincode': pincode,
    };
    return _api.post(getPincodeDetailsPoint, body, token: token);
  }

  Future<APIResponse> getPincodeDetailsRegister(String pincode) async {
    final body = {
      'pincode': pincode,
    };
    return _api.post(
      getPincodeDetailsRegisterPoint,
      body,
    );
  }

  Future<APIResponse> getAllAeraByZip(String token, String pincode) async {
    final body = {
      'pincode': pincode,
    };
    return _api.post(getAllAreaByZipcodePoint, body, token: token);
  }

  Future<APIResponse> getAllAeraByZipRegistration(String pincode) async {
    final body = {
      'pincode': pincode,
    };
    return _api.post(
      getAllAeraByZipRegisterPoint,
      body,
    );
  }

  Future<APIResponse> getShipmentDataList(
    final token,
    final userID,
    final nextID,
    final shimentStatus,
    final receiverGSTNo,
    final senderGSTNo,
    final receiverAeraName,
    final senderAeraName,
    final destination,
    final orgin,
    final receiverCompanyName,
    final senderCompanyName,
    final shipmentID,
    final role,
    final search_query,
  ) async {
    final body = {
      'user_id': userID,
      'next_id': nextID,
      'shipment_status': shimentStatus,
      'receiver_gst_no': receiverGSTNo,
      'sender_gst_no': senderGSTNo,
      'receiver_areaname': receiverAeraName,
      'sender_areaname': senderAeraName,
      'destination': destination,
      'origin': orgin,
      'receiver_company_name': receiverCompanyName,
      'sender_company_name': senderCompanyName,
      'shipment_id': shipmentID,
      'role': role,
      'search_query': search_query,
    };
    return _api.post(
      getShipmentDataListPoint,
      token: token,
      body,
    );
  }

// post call

  Future<APIResponse> customerRegister(
    final companyName,
    final fullName,
    final categoryID,
    final natureBusinessID,
    final email,
    final mobile,
    final telephone,
    final faxNo,
    final gstNo,
    final panNo,
    final axlplInsuranceValue,
    final thirdPartyInsuranceValue,
    final thirdPartyPolicyNo,
    final thirdPartyExpDate,
    final password,
    final countryID,
    final stateID,
    final cityID,
    final areaID,
    final pincode,
    final address1,
    final address2,
    final uploadProfile,
    final uploadGst,
    final uploadPan,
  ) async {
    // Convert files to MultipartFile (following your POD repo pattern)
    MultipartFile? profileAttachment;
    MultipartFile? gstAttachment;
    MultipartFile? panAttachment;

    // Profile is optional
    if (uploadProfile != null) {
      profileAttachment = await MultipartFile.fromFile(
        uploadProfile.path,
        filename: uploadProfile.path.split('/').last,
      );
    }

    // GST is required
    if (uploadGst != null) {
      gstAttachment = await MultipartFile.fromFile(
        uploadGst.path,
        filename: uploadGst.path.split('/').last,
      );
    }

    // PAN is required
    if (uploadPan != null) {
      panAttachment = await MultipartFile.fromFile(
        uploadPan.path,
        filename: uploadPan.path.split('/').last,
      );
    }

    final body = FormData.fromMap({
      // Match exact Postman field names
      'company_name': companyName,
      'full_name': fullName,
      'category': categoryID,
      'nature_of_business': natureBusinessID,
      'reg_address1': address1, // Changed from 'registered_address1'
      'reg_address2': address2, // Changed from 'registered_address2'
      'country_id': countryID,
      'state_id': stateID,
      'city_id': cityID,
      'area_id': areaID,
      'branch_id': '1', // Changed from 'cust_branch_id'
      'pincode': pincode,
      'mobile_no': mobile,
      'tel_no': telephone,
      'fax_no': faxNo,
      'email': email, // Changed from 'email_address'
      'password': password,
      'pan_no': panNo,
      'gst_no': gstNo,
      'axlpl_insurance_value': axlplInsuranceValue,
      'third_party_insurance_value': thirdPartyInsuranceValue,
      'third_party_policy_no': thirdPartyPolicyNo,
      'third_party_exp_date': thirdPartyExpDate,
      // Add files (required files should always be present)
      'upload_gst': gstAttachment,
      'upload_pancard': panAttachment,
      // Optional profile image
      if (profileAttachment != null) 'cust_profile_img': profileAttachment,
    });

    log('FormData fields: ${body.fields}');
    log('FormData files: ${body.files.map((e) => e.key).toList()}');

    return _api.post(customerRegisterPoint, body);
  }

  Future<APIResponse> loginUserService(
    String mobile,
    // final email,
    String password,
    String fcmToken,
    String appVersion,
    String latitude,
    String longitude,
    String deviceId,

    // String token
  ) {
    final Map<String, dynamic> body = {
      'mobile': mobile,
      'password': password,
      'fcm_token': fcmToken,
      // 'token': token,
      'version': appVersion,
      'latitude': latitude,
      'longitude': longitude,
      'device_id': deviceId,
    };

    return _api.post(loginPoint, body);
  }

  Future<APIResponse> verifyLoginOtpService(
    String mobile,
    // final email,
    String otp,

    // String token
  ) {
    final Map<String, dynamic> body = {
      'mobile': mobile,
      'otp': otp,
    };

    return _api.post(verifyLoginOtpPoint, body);
  }

  Future<APIResponse> logout(
    String userID,
    String role,
    String latitude,
    String longitude,
    final token,
    final deviceId,
  ) {
    final body = {
      'm_id': userID,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'device_id': deviceId,
    };
    return _api.post(
      logoutPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> addShipment({
    required ShipmentModel shipmentModel,
    required String token,
  }) async {
    // Convert ShipmentModel to JSON map
    final body = shipmentModel.toJson();

    // Add token if your API requires it in body (or in headers as needed)
    body['token'] = token;

    // Optional: log body for debugging
    log("Shipment API Body: ${json.encode(body)}");

    // Call your API post method
    return _api.post(addShipmentPoint, body, token: token);
  }

  Future<APIResponse> getShipmentCalculation(
    final custID,
    final cateID,
    final commID,
    final netWeight,
    final grossWeight,
    final paymentMode,
    final invoiceValue,
    final insuranceByAxlpl,
    final policyNo,
    final numberOfParcel,
    final expDate,
    final policyValue,
    final senderZip,
    final receiverZip,
  ) async {
    final body = {
      'customer_id': custID,
      'category_id': cateID,
      'commodity_id': commID,
      'net_weight': netWeight,
      'gross_weight': grossWeight,
      'payment_mode': paymentMode,
      'invoice_value': invoiceValue,
      'insurance_by_AXLPL': insuranceByAxlpl,
      'policy_no': policyNo,
      'number_of_parcel': numberOfParcel,
      'policy_expirydate': expDate,
      'policy_value': policyValue,
      'sender_zipcode': senderZip,
      'receiver_zipcode': receiverZip
    };
    return _api.post(
      getShipmentCalclulationPoint,
      body,
    );
  }

  Future<APIResponse> changePassword(
    String id,
    String oldPassword,
    String newPassword,
    String role,
    String token,
  ) {
    final body = {
      'id': id,
      'old_password': oldPassword,
      'new_password': newPassword,
      'user_type': role,
    };
    return _api.post(
      changePasswordPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getMessangerRatting(
    String id,
    String token,
  ) {
    final body = {
      'messanger_id': id,
    };
    return _api.post(
      getRatting,
      body,
      token: token,
    );
  }

  Future<APIResponse> tracking(
    String shipmentID,
    String token,
  ) {
    final body = {
      'shipment_id': shipmentID,
    };
    return _api.post(
      trackPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> uploadPOD(
    final shipmentID,
    final shipmentStatus,
    final shipmentOtp,
    MultipartFile? attachment,
    final token,
  ) async {
    final formData = FormData.fromMap({
      'shipment_id': shipmentID,
      'shipment_status': shipmentStatus,
      'shipment_otp': shipmentOtp,
      'attachment': attachment,
    });

    // ✅ Add these lines for debugging
    log("FormData Fields: ${formData.fields}");

    // ✅ Pass correct content type here
    return _api.post(
      uploadPODPoint,
      formData,
      token: token,
      contentType: ContentType.multipart, // <-- ADD THIS
    );
  }

  Future<APIResponse> uploadInvoice(
    final shipmentID,
    List<MultipartFile> attachments,
    final token,
  ) async {
    final formData = FormData();
    formData.fields.add(MapEntry('shipment_id', shipmentID.toString()));
    for (final file in attachments) {
      formData.files.add(MapEntry('invoice_file[]', file));
    }
    return _api.post(
      uploadInvoicePoint,
      formData,
      token: token,
      contentType: ContentType.multipart,
    );
  }

  Future<APIResponse> deleteShipmentInvoiceFile({
    String? invoiceFileId,
    String? fileName,
    required token,
  }) async {
    final formData = FormData();
    final id = invoiceFileId?.trim();
    final name = fileName?.trim();
    if (id != null && id.isNotEmpty) {
      formData.fields.add(MapEntry('id', id));
    }
    if (name != null && name.isNotEmpty) {
      formData.fields.add(MapEntry('file_name', name));
    }
    return _api.post(
      '',
      formData,
      token: token,
      query: {
        'request': deleteShipmentInvoiceFilePoint,
        if (id != null && id.isNotEmpty) 'id': id,
        if (name != null && name.isNotEmpty) 'file_name': name,
      },
      contentType: ContentType.multipart,
    );
  }

  Future<APIResponse> contractView(final custID) async {
    final body = {
      'customer_id': custID,
    };
    return _api.post(
      contractViewPoint,
      body,
    );
  }

  Future<APIResponse> usedContract(final custID, final contractID) async {
    final body = {
      'customer_id': custID,
      'contract_id': contractID,
    };
    return _api.post(
      getUsedContractPoint,
      body,
    );
  }

  Future<APIResponse> uploadPickup(
    shipmentID,
    shipmentStatus,
    id,
    date,
    lat,
    long,
    cashAmount,
    paymentMode,
    subPaymentMode,
    final otp,
    token, {
    // Start of optional named parameters
    String? chequeNumber,
  }) async {
    final body = {
      'shipment_id': shipmentID,
      'status': shipmentStatus,
      'messanger_id': id,
      'date_time': date,
      'latitude': lat,
      'longitude': long,
      'cash_amount': cashAmount,
      'payment_method': paymentMode,
      'sub_payment_mode': subPaymentMode,
      'pickup_otp': otp,
    };

    if (chequeNumber != null && chequeNumber.isNotEmpty) {
      body['cheque_number'] = chequeNumber;
    }

    return _api.post(
      uploadPickupPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> uploadDelivery(
    shipmentID,
    shipmentStatus,
    id,
    date,
    lat,
    long,
    amtPaid,
    cashAmount,
    paymentMode,
    subPaymentMode,
    deliveryOtp,
    token, {
    // Start of optional named parameters
    String? chequeNumber,
    String? receiverName,
  }) async {
    final body = {
      'shipment_id': shipmentID,
      'status': shipmentStatus,
      'messanger_id': id,
      'date_time': date,
      'latitude': lat,
      'longitude': long,
      'amount_paid': amtPaid,
      'cash_amount': cashAmount,
      'payment_method': paymentMode,
      'sub_payment_mode': subPaymentMode,
      'delivery_otp': deliveryOtp,
      'cheque_number': chequeNumber ?? 0,
      'receiver_name': receiverName ?? '',
    };

    return _api.post(
      uploadDeliveryPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getOtp(
    final shipmentID,
  ) async {
    final body = {
      'shipment_id': shipmentID,
    };
    return _api.post(
      getOtpPoint,
      body,
    );
  }

  Future<APIResponse> getShipmentRecord(
    final shipmentID,
    final token,
  ) async {
    final body = {
      'shipment_id': shipmentID,
    };
    return _api.post(
      getShipmentRecordPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> updateProfile(
    String id,
    String role,
    String name,
    String email,
    String mobile,
    final profileUpdate,
  ) async {
    final formData = FormData.fromMap({
      'id': id,
      'user_role': role,
      'name': name,
      'email': email,
      'mobile_no': mobile,
      // Conditionally set the photo field based on role
      if (profileUpdate != null)
        role == 'customer' ? 'customer_photo' : 'messanger_photo':
            profileUpdate,
    });
    return _api.post(
      updateProfilePoint,
      formData,
    );
  }

  Future<APIResponse> getProfile(final id, final role) async {
    final body = {
      'id': id,
      'user_role': role,
    };
    return _api.post(
      editProfilePoint,
      body,
    );
  }

  Future<APIResponse> getAllPickup(
    final id,
    final brachID,
    final nextID,
    final token,
  ) {
    final body = {
      'messanger_id': id,
      'branch_id': brachID,
      'next_id': nextID,
      'token': token,
    };
    return _api.post(
      getAllPickupPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> rateMessanger(
    final id,
    final shipmentID,
    final rating,
    final feedback,
  ) {
    final body = {
      'messanger_id': id,
      'shipment_id': shipmentID,
      'rating': rating,
      'feedback': feedback,
    };
    return _api.post(
      ratingPoint,
      body,
    );
  }

  Future<APIResponse> grossCalculation(
    final netWeight,
    final grossWeight,
    final status,
    final productID,
    final contractWeight,
    final contractRate,
  ) {
    final body = {
      'net_weight': netWeight,
      'gross_weight': grossWeight,
      'calculation_status': status,
      'product_id': productID,
      'contract_weight': contractWeight,
      'contract_rate': contractRate,
    };
    return _api.post(
      grosssCalculationPoint,
      body,
    );
  }

  Future<APIResponse> getNotificationList(
    final id,
    final nextID,
    final token,
  ) {
    final body = {
      'm_id': id,
      'next_id': nextID,
      'token': token,
    };
    return _api.post(
      getNotificationListPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> transferShipment(
    final shipmentID,
    final transferByID,
    final transferToID,
    final shipmentType,
  ) {
    final body = {
      "shipment_id": shipmentID,
      "transfer_by": transferByID,
      "transfer_to": transferToID,
      "shipment_type": shipmentType,
    };
    return _api.post(transferShipmentPoint, body);
  }

  Future<APIResponse> getAllMessanger(
    final messangerID,
    final routeID,
    final lat,
    final long,
    final nextID,
    final token,
  ) {
    final query = {
      "m_id": messangerID,
      "route": routeID,
      "latitude": lat,
      "longitude": long,
      "next_id": nextID,
    };
    return _api.get(
      getAllMessangerPoint,
      token: token,
      query: query,
    );
  }

  Future<APIResponse> getContractDetails(
    final customerID,
    final categoryID,
    final token,
  ) {
    final body = {
      'customer_id': customerID,
      'category_id': categoryID,
    };
    return _api.post(
      getContractDetailsPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getCustomerInvoice(
    final custID,
  ) {
    final body = {"customer_id": custID};
    return _api.post(getCustomerInvoicePoint, body);
  }

  Future<APIResponse> getPaymentMode() {
    return _api.get(
      getPaymentModePoint,
    );
  }

  Future<APIResponse> getCashCollectionLog(
    final token,
    final nextID,
    final userID,
  ) {
    final body = {
      'token': token,
      'next_id': nextID,
      'messanger_id': userID,
    };
    return _api.post(
      getCashCollectionLogPoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getCustomerCategory(
    final token,
  ) {
    return _api.get(
      getCustomerCategoryPoint,
      token: token,
    );
  }

  Future<APIResponse> getNatureOfBusiness(
    final token,
  ) {
    return _api.get(
      getNatureOfBusinessPoint,
      token: token,
    );
  }

  Future<APIResponse> deleteAccount(
    final id,
    final role,
    final token,
  ) {
    final body = {
      'id': id,
      'user_role': role,
    };
    return _api.post(
      deleteProfilePoint,
      body,
      token: token,
    );
  }

  Future<APIResponse> getAllStatuses({required String token}) async {
    final response = await _api.post(
      'getStatus',
      {},
      token: token,
      contentType: ContentType.urlEncoded,
    );
    return response;
  }

  Future<APIResponse> getNegativeStatusList({
    required String token,
    String? status,
    String? statusId,
  }) async {
    final query = <String, dynamic>{};
    final statusValue = status?.trim();
    final statusIdValue = statusId?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      query['status'] = statusValue;
    }
    if (statusIdValue != null && statusIdValue.isNotEmpty) {
      query['status_id'] = statusIdValue;
    }
    final response = await _api.get(
      getNegativeStatusListPoint,
      token: token,
      query: query.isEmpty ? null : query,
      contentType: ContentType.urlEncoded,
    );
    return response;
  }

  Future<APIResponse> getNegativeStatusListPost({
    required String token,
    String? status,
    String? statusId,
  }) async {
    final body = <String, dynamic>{};
    final statusValue = status?.trim();
    final statusIdValue = statusId?.trim();
    if (statusValue != null && statusValue.isNotEmpty) {
      body['status'] = statusValue;
    }
    if (statusIdValue != null && statusIdValue.isNotEmpty) {
      body['status_id'] = statusIdValue;
    }
    final response = await _api.post(
      getNegativeStatusListPoint,
      body,
      token: token,
      contentType: ContentType.urlEncoded,
    );
    return response;
  }

  // ---------------------------
  // Update Shipment Status
  // ---------------------------
  Future<APIResponse> updateShipmentStatus({
    required String token,
    required String shipmentId,
    required String shipmentStatus,
  }) async {
    final body = FormData.fromMap({
      'shipment_id': shipmentId,
      'shipment_status': shipmentStatus,
    });

    return _api.post(
      'update_shipment_status',
      body,
      token: token,
      contentType: ContentType.multipart,
    );
  }

  Future<APIResponse> updateShipmentStatusNew({
    required String token,
    required String shipmentId,
    required String shipmentStatus,
    required String isNegative,
    String? negativeStatus,
    String? negativeRemark,
    String? receiverName,
    String? messangerId,
  }) async {
    final body = {
      'shipment_id': shipmentId,
      'shipment_status': shipmentStatus,
      'is_negative': isNegative,
      'negative_status': negativeStatus ?? '',
      'negative_remark': negativeRemark ?? '',
      'receiver_name': receiverName ?? '',
      'messanger_id': messangerId ?? '',
    };

    return _api.post(
      updateShipmentStatusNewPoint,
      body,
      token: token,
      contentType: ContentType.urlEncoded,
    );
  }

  // =========================
  // Outbound — Reference data
  // =========================

  Future<APIResponse> getBranches({
    required String token,
  }) async {
    return _api.getOutbound(
      getBranchesPoint,
      token: token,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> getAirlines({
    required String token,
  }) async {
    return _api.getOutbound(
      getAirlinesPoint,
      token: token,
      contentType: ContentType.urlEncoded,
    );
  }

  // =========================
  // Outbound — Hub scan
  // =========================

  Future<APIResponse> hubScan({
    required String token,
    required String docketNo,
    required String branchId,
    required String userId,
    required String status,
  }) async {
    // Production iOS: multipart POST api.php?request=hubscan (no platform param).
    final body = FormData.fromMap({
      'docket_no': docketNo,
      'branch_id': branchId,
      'user_id': userId,
      'status': status,
    });
    return _api.postOutbound(
      hubScanPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  /// POST `hubScanFetchShipment` — multipart `connote` (scanned shipment / docket).
  Future<APIResponse> hubScanFetchShipment({
    required String token,
    required String connote,
  }) async {
    final body = FormData.fromMap({'connote': connote.trim()});
    return _api.postOutbound(
      hubScanFetchShipmentPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> getHubScanLogs({
    required String token,
    required String branchId,
    required int limit,
    int offset = 0,
  }) async {
    // GET api.php?request=gethubscanlogs&branch_id=&limit=&offset=
    final query = <String, String>{
      'branch_id': branchId,
      'limit': limit.toString(),
    };
    if (offset > 0) {
      query['offset'] = offset.toString();
    }
    return _api.getOutbound(
      getHubScanLogsPoint,
      token: token,
      query: query,
      appendPlatform: false,
    );
  }

  Future<APIResponse> getShipmentScanHistory({
    required String token,
    required String docketNo,
  }) async {
    return _api.getOutbound(
      getShipmentScanHistoryPoint,
      token: token,
      appendPlatform: false,
      query: {'docket_no': docketNo},
      contentType: ContentType.urlEncoded,
    );
  }

  // =========================
  // Outbound — Bagging
  // =========================

  Future<APIResponse> createBag({
    required String token,
    required String originBranchId,
    required String destinationBranchId,
    required String metalSealNo,
    required String userId,
    required String shipmentIds,
    String? bagCode,
  }) async {
    final body = FormData.fromMap({
      'origin_branch_id': originBranchId.trim(),
      'destination_branch_id': destinationBranchId.trim(),
      'user_id': userId,
      ...OutboundApiParams.createBagBody(
        metalSealNo: metalSealNo,
        shipmentIdsCsv: shipmentIds,
        bagCode: bagCode,
      ),
    });
    return _api.postOutbound(
      createBagPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> addShipmentToBag({
    required String token,
    required String bagCode,
    required String docketNo,
    required String branchId,
    required String userId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.bagDocketMutationBody(
        bagRef: bagCode,
        docketNo: docketNo,
        branchId: branchId,
        userId: userId,
      ),
    );
    return _api.postOutbound(
      addShipmentToBagPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> getBagDetails({
    required String token,
    required String bagCode,
  }) async {
    return getBagDetailsQuery(token: token, query: {'bag_code': bagCode});
  }

  Future<APIResponse> getBagDetailsQuery({
    required String token,
    required Map<String, String> query,
  }) async {
    return _api.getOutbound(
      getBagDetailsPoint,
      token: token,
      query: query,
      appendPlatform: false,
    );
  }

  Future<APIResponse> listBags({
    required String token,
    required String branchId,
  }) async {
    return _api.getOutbound(
      listBagsPoint,
      token: token,
      query: {'branch_id': branchId},
      appendPlatform: false,
    );
  }

  Future<APIResponse> removeShipmentFromBag({
    required String token,
    required String bagCode,
    required String docketNo,
    required String branchId,
    required String userId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.bagDocketMutationBody(
        bagRef: bagCode,
        docketNo: docketNo,
        branchId: branchId,
        userId: userId,
      ),
    );
    return _api.postOutbound(
      removeShipmentFromBagPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> lockBag({
    required String token,
    required String bagCode,
  }) async {
    final body = FormData.fromMap(OutboundApiParams.bagMutationBody(bagCode));
    return _api.postOutbound(
      lockBagPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> rebagShipment({
    required String token,
    required String newBagCode,
    required String docketNo,
    required String userId,
  }) async {
    final body = FormData.fromMap({
      ...OutboundApiParams.bagMutationBody(newBagCode, idKey: 'new_bag_code'),
      'docket_no': docketNo,
      'user_id': userId,
    });
    return _api.postOutbound(
      rebagShipmentPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> baggingReport({
    required String token,
    required String bagCode,
    String? startDate,
    String? endDate,
  }) async {
    return _api.getOutbound(
      baggingReportPoint,
      token: token,
      query: OutboundApiParams.baggingReportQuery(
        bagCode: bagCode,
        startDate: startDate,
        endDate: endDate,
      ),
      appendPlatform: false,
    );
  }

  // =========================
  // Outbound — Manifest
  // =========================

  Future<APIResponse> createManifest({
    required String token,
    required String bagCodesCsv,
    required String originBranchId,
    required String destinationBranchId,
    required String userId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.createManifestBody(
        bagCodesCsv: bagCodesCsv,
        originBranchId: originBranchId,
        destinationBranchId: destinationBranchId,
        userId: userId,
      ),
    );
    return _api.postOutbound(
      createManifestPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> getManifestDetails({
    required String token,
    required String manifestId,
  }) async {
    return getManifestDetailsQuery(
      token: token,
      query: {'manifest_code': manifestId},
    );
  }

  Future<APIResponse> getManifestDetailsQuery({
    required String token,
    required Map<String, String> query,
  }) async {
    return _api.getOutbound(
      getManifestDetailsPoint,
      token: token,
      query: query,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> listManifests({
    required String token,
    required String branchId,
  }) async {
    return _api.getOutbound(
      listManifestsPoint,
      token: token,
      query: {'branch_id': branchId},
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> manifestReport({
    required String token,
    required String startDate,
    required String endDate,
    required String manifestNo,
  }) async {
    return _api.getOutbound(
      manifestReportPoint,
      token: token,
      query: OutboundApiParams.manifestReportQuery(
        manifestNo: manifestNo,
        startDate: startDate,
        endDate: endDate,
      ),
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> printManifestData({
    required String token,
    required String manifestId,
  }) async {
    return printManifestDataQuery(
      token: token,
      query: {'manifest_code': manifestId},
    );
  }

  Future<APIResponse> printManifestDataQuery({
    required String token,
    required Map<String, String> query,
  }) async {
    return _api.getOutbound(
      printManifestDataPoint,
      token: token,
      query: query,
      contentType: ContentType.urlEncoded,
    );
  }

  // =========================
  // Outbound — Linehaul
  // =========================

  Future<APIResponse> assignLinehaul({
    required String token,
    required String manifestIdsCommaSeparated,
    required String vehicleNo,
    required String driverName,
    required String userId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.assignLinehaulBody(
        manifestCodesCsv: manifestIdsCommaSeparated,
        vehicleNo: vehicleNo,
        driverName: driverName,
        userId: userId,
      ),
    );
    return _api.postOutbound(
      assignLinehaulPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> listLinehauls({
    required String token,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    final filter = status?.trim();
    if (filter != null && filter.isNotEmpty) {
      query['status'] = filter;
    }
    return _api.getOutbound(
      listLinehaulsPoint,
      token: token,
      query: query.isEmpty ? null : query,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> getLinehaulDetails({
    required String token,
    required String linehaulId,
  }) async {
    return getLinehaulDetailsQuery(
      token: token,
      query: {'trip_no': linehaulId},
    );
  }

  Future<APIResponse> getLinehaulDetailsQuery({
    required String token,
    required Map<String, String> query,
  }) async {
    return _api.getOutbound(
      getLinehaulDetailsPoint,
      token: token,
      query: query,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> updateLinehaulStatus({
    required String token,
    required String linehaulRef,
    required String status,
    required String userId,
    required String branchId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.updateLinehaulStatusBody(
        linehaulRef: linehaulRef,
        status: status,
        userId: userId,
        branchId: branchId,
      ),
    );
    return _api.postOutbound(
      updateLinehaulStatusPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> linehaulReport({
    required String token,
    required String startDate,
    required String endDate,
  }) async {
    return _api.getOutbound(
      linehaulReportPoint,
      token: token,
      query: {
        'start_date': startDate,
        'end_date': endDate,
      },
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> editLinehaul({
    required String token,
    required Map<String, String> body,
  }) async {
    return _api.postOutbound(
      editLinehaulPoint,
      body,
      token: token,
      contentType: ContentType.urlEncoded,
      appendPlatform: false,
    );
  }

  Future<APIResponse> deleteLinehaul({
    required String token,
    required String linehaulId,
    String? tripNo,
    String? mawbNo,
  }) async {
    return _api.postOutbound(
      deleteLinehaulPoint,
      OutboundApiParams.deleteLinehaulBody(
        linehaulId: linehaulId,
        tripNo: tripNo,
        mawbNo: mawbNo,
      ),
      token: token,
      contentType: ContentType.urlEncoded,
      appendPlatform: false,
    );
  }

  // =========================
  // Outbound — Sector pickup
  // =========================

  Future<APIResponse> sectorPickupScan({
    required String token,
    required String pickupId,
    required String docketNo,
    required String status,
    required String remarks,
    required String userId,
    required String branchId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.sectorPickupScanBody(
        pickupId: pickupId,
        docketNo: docketNo,
        status: status,
        remarks: remarks,
        userId: userId,
        branchId: branchId,
      ),
    );
    return _api.postOutbound(
      sectorPickupScanPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> getPickupListOutbound({
    required String token,
  }) async {
    return _api.getOutbound(
      getPickupListPoint,
      token: token,
      query: null,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> getPickupDetail({
    required String token,
    required String pickupId,
  }) async {
    return _api.getOutbound(
      getPickupDetailPoint,
      token: token,
      query: {'pickup_id': pickupId},
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> markNotPicked({
    required String token,
    required String pickupId,
    required String docketNo,
    required String remarks,
    required String userId,
    required String branchId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.markNotPickedBody(
        pickupId: pickupId,
        docketNo: docketNo,
        remarks: remarks,
        userId: userId,
        branchId: branchId,
      ),
    );
    return _api.postOutbound(
      markNotPickedPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> addMissedShipment({
    required String token,
    required String pickupId,
    required String docketNo,
    required String remarks,
    required String userId,
    required String branchId,
  }) async {
    final body = FormData.fromMap(
      OutboundApiParams.addMissedShipmentBody(
        pickupId: pickupId,
        docketNo: docketNo,
        remarks: remarks,
        userId: userId,
        branchId: branchId,
      ),
    );
    return _api.postOutbound(
      addMissedShipmentPoint,
      body,
      token: token,
      contentType: ContentType.multipart,
      appendPlatform: false,
    );
  }

  Future<APIResponse> pickupReportOutbound({
    required String token,
    String? startDate,
    String? endDate,
    int? page,
    String? originBranch,
    String? destinationBranch,
    String? docketNo,
    String? status,
    String? linehaulNo,
  }) async {
    final query = <String, String>{};
    final start = startDate?.trim();
    if (start != null && start.isNotEmpty) query['start_date'] = start;
    final end = endDate?.trim();
    if (end != null && end.isNotEmpty) query['end_date'] = end;
    if (page != null && page > 0) query['page'] = '$page';
    final origin = originBranch?.trim();
    if (origin != null && origin.isNotEmpty) query['origin_branch'] = origin;
    final dest = destinationBranch?.trim();
    if (dest != null && dest.isNotEmpty) {
      query['destination_branch'] = dest;
    }
    final docket = docketNo?.trim();
    if (docket != null && docket.isNotEmpty) query['docket_no'] = docket;
    final st = status?.trim();
    if (st != null && st.isNotEmpty) query['status'] = st;
    final linehaul = linehaulNo?.trim();
    if (linehaul != null && linehaul.isNotEmpty) {
      query['linehaul_no'] = linehaul;
    }
    return _api.getOutbound(
      pickupReportPoint,
      token: token,
      query: query,
      contentType: ContentType.urlEncoded,
    );
  }

  Future<APIResponse> sectorPickupReportExportOutbound({
    required String token,
    String? startDate,
    String? endDate,
    String? originBranch,
    String? destinationBranch,
    String? docketNo,
    String? status,
    String? linehaulNo,
  }) async {
    final query = <String, String>{'export': '1'};
    final start = startDate?.trim();
    if (start != null && start.isNotEmpty) query['start_date'] = start;
    final end = endDate?.trim();
    if (end != null && end.isNotEmpty) query['end_date'] = end;
    final origin = originBranch?.trim();
    if (origin != null && origin.isNotEmpty) query['origin_branch'] = origin;
    final dest = destinationBranch?.trim();
    if (dest != null && dest.isNotEmpty) {
      query['destination_branch'] = dest;
    }
    final docket = docketNo?.trim();
    if (docket != null && docket.isNotEmpty) query['docket_no'] = docket;
    final st = status?.trim();
    if (st != null && st.isNotEmpty) query['status'] = st;
    final linehaul = linehaulNo?.trim();
    if (linehaul != null && linehaul.isNotEmpty) {
      query['linehaul_no'] = linehaul;
    }
    return _api.getOutbound(
      sectorPickupReportPoint,
      token: token,
      query: query,
      contentType: ContentType.urlEncoded,
    );
  }
}
