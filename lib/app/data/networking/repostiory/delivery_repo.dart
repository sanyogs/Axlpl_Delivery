import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/common_model.dart';
import 'package:axlpl_delivery/app/data/models/history_delivery_model.dart';
import 'package:axlpl_delivery/app/data/models/history_pickup_model.dart';
import 'package:axlpl_delivery/app/data/models/lat_long_model.dart';
import 'package:axlpl_delivery/app/data/models/status_model.dart';
import 'package:axlpl_delivery/app/data/models/update_status_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_services.dart';
import 'package:axlpl_delivery/utils/utils.dart';

class DeliveryRepo {
  final ApiServices _apiServices = ApiServices();

  Future<List<HistoryDelivery>?> deliveryHistoryRepo(
      final zipcode,
      final nextID,
      ) async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final userID = userData?.messangerdetail?.id?.toString() ??
          userData?.customerdetail?.id.toString();
      final branchID = userData?.messangerdetail?.branchId ??
          userData?.customerdetail?.branchId.toString();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

      if (userID?.isNotEmpty == true || userID != null) {
        final response = await _apiServices.getDeliveryHistory(
          userID.toString(),
          zipcode ?? '0',
          branchID.toString(),
          nextID,
          token.toString(),
        );
        return response.when(
          success: (body) {
            final historyData = DeliveryHistoryModel.fromJson(body);
            if (historyData.status == "success") {
              return historyData.historyDelivery;
            } else {
              Utils().logInfo(
                  'API call successful but status is not "success" : ${historyData.status}');
              return [];
            }
          },
          error: (error) {
            Utils().logError("History Failed: ${error.toString()}");
            return [];
          },
        );
      }
    } catch (e) {
      Utils().logError("$e");
    }
    return null;
  }

  Future<List<HistoryPickup>?> pickupHistoryRepo() async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final userID = userData?.messangerdetail?.id?.toString() ??
          userData?.customerdetail?.id.toString();
      final branchID = userData?.messangerdetail?.branchId ??
          userData?.customerdetail?.branchId.toString();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;
      if (userID?.isNotEmpty == true || userID != null) {
        final response = await _apiServices.getPickupHistory(
            userID.toString(), branchID.toString(), token.toString());
        return response.when(
          success: (body) {
            final historyData = HistoryPickupModel.fromJson(body);
            if (historyData.status == "success") {
              return historyData.historyPickup;
            } else {
              Utils().logInfo(
                  'API call successful but status is not "success" : ${historyData.status}');
              return [];
            }
          },
          error: (error) {
            Utils().logError("Pickup History Failed: ${error.toString()}");
            return [];
          },
        );
      }
    } catch (e) {
      Utils().logError("$e");
    }
    return null;
  }

  Future<bool> uploadDeliveryRepo(
      shipmentID,
      shipmentStatus,
      id,
      date,
      amtPaid,
      cashAmount,
      paymentMode,
      subPaymentMode,
      deliveryOtp, {
        String? chequeNumber,
      }) async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final userID = userData?.messangerdetail?.id?.toString();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

      if (userID == null || userID.isEmpty) {
        Utils().logError("User ID is null or empty, cannot upload pickup.");
        return false;
      }

      final response = await _apiServices.uploadDelivery(
        shipmentID,
        shipmentStatus,
        id,
        date,
        '0',
        '0',
        amtPaid,
        cashAmount,
        paymentMode,
        subPaymentMode,
        deliveryOtp,
        token.toString(),
        chequeNumber: chequeNumber,
      );

      bool isSuccess = false;

      response.when(
        success: (body) {
          final data = CommonModel.fromJson(body);
          if (data.status == 'success') {
            Utils().log(data.toJson());
            isSuccess = true;
          } else {
            Utils().log('Delivery error: ${data.message}');
            Utils().log(data.toJson());
            isSuccess = false;
          }
        },
        error: (error) {
          Utils().logError(error.toString());
          isSuccess = false;
        },
      );
      return isSuccess;
    } catch (e) {
      Utils().logError(e.toString());
      return false;
    }
  }

  Future<List<StatusModel>?> fetchStatuses() async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

      if (token == null || token.isEmpty) {
        Utils().logError("Token is null or empty, cannot fetch status list.");
        return [];
      }

      final response = await _apiServices.getAllStatuses(token: token);

      return response.when(
        success: (body) {
          if (body['status'] == 'success') {
            final list = (body['Status'] as List)
                .map((e) => StatusModel.fromJson(e))
                .toList();
            return list;
          } else {
            Utils().logInfo(
                'API call successful but status is not "success" : ${body['message']}');
            return [];
          }
        },
        error: (error) {
          Utils().logError("Fetch Status Failed: ${error.toString()}");
          return [];
        },
      );
    } catch (e) {
      Utils().logError(e.toString());
      return [];
    }
  }

  // ---------------------------
  // 🔹 Update Shipment Status Repo
  // ---------------------------
  Future<UpdateStatusModel?> updateShipmentStatusRepo({
    required String shipmentId,
    required String shipmentStatus,
  }) async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

      if (token == null || token.isEmpty) {
        Utils().logError("Token not found, cannot update shipment status.");
        return null;
      }

      final response = await _apiServices.updateShipmentStatus(
        token: token,
        shipmentId: shipmentId,
        shipmentStatus: shipmentStatus,
      );

      return response.when(
        success: (body) {
          final model = UpdateStatusModel.fromJson(body);
          if (model.status == "success") {
            Utils().logInfo(
                'Shipment status updated successfully: ${model.statusText}');
            return model;
          } else {
            Utils().logError('Update failed: ${model.message}');
            return model;
          }
        },
        error: (error) {
          Utils().logError("Error updating shipment status: ${error.toString()}");
          return null;
        },
      );
    } catch (e) {
      Utils().logError("Error updating shipment status: $e");
      return null;
    }
  }
}
