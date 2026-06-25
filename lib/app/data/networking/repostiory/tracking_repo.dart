import 'dart:developer';
import 'dart:io';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/common_model.dart';
import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_services.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:dio/dio.dart';

class TrackingRepo {
  final ApiServices _apiServices = ApiServices();
  String? apiMessage;
  final LocalStorage _localStorage = LocalStorage();
  Future<TrackingModel?> trackingRepo(
    final shipmentID,
  ) async {
    try {
      final userData = await LocalStorage().getUserLocalData();
      final token =
          userData?.messangerdetail?.token ?? userData?.customerdetail?.token;
      final response = await _apiServices.tracking(
        shipmentID,
        token.toString(),
      );
      return response.when(
        success: (body) {
          final trackingData = TrackingModel.fromJson(body);
          if (trackingData.message == 'Success') {
            return trackingData;
          } else {
            return throw Exception(trackingData.message);
          }
        },
        error: (error) {
          throw Exception(error.toString());
        },
      );
    } catch (e) {
      Utils().logError(e.toString());
    }
    return null;
  }

  Future<bool> uploadInvoiceRepo(
    String shipmentID,
    List<File> files,
  ) async {
    apiMessage = null;

    final userData = await _localStorage.getUserLocalData();
    final token =
        userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

    try {
      final attachments = <MultipartFile>[];
      for (final file in files) {
        if (!await file.exists()) continue;
        attachments.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }
      if (attachments.isEmpty) {
        apiMessage = 'No valid invoice files to upload.';
        return false;
      }

      final response = await _apiServices.uploadInvoice(
        shipmentID,
        attachments,
        token,
      );

      return response.when(
        success: (body) {
          log("API Success Body: $body");
          final apiStatus = CommonModel.fromJson(body);

          if (apiStatus.status != 'success') {
            throw Exception(
                apiStatus.message ?? "Invoice Upload Failed: Unknown Error");
          } else {
            apiMessage = apiStatus.message;
          }

          return true;
        },
        error: (exception) {
          throw Exception("Invoice Upload Failed: ${exception.toString()}");
        },
      );
    } catch (e) {
      final errorMessage = "Unexpected Error: $e";
      Utils.instance.log(errorMessage);
      return false;
    }
  }
}
