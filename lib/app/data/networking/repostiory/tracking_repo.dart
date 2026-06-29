import 'dart:developer';
import 'dart:io';

import 'package:axlpl_delivery/app/data/models/invoice_delete_result_model.dart';
import 'package:axlpl_delivery/app/data/models/invoice_upload_result_model.dart';
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

  Future<InvoiceUploadResult> uploadInvoiceRepo(
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
        return const InvoiceUploadResult(success: false);
      }

      final response = await _apiServices.uploadInvoice(
        shipmentID,
        attachments,
        token,
      );

      return response.when(
        success: (body) {
          log("API Success Body: $body");
          final parsed = InvoiceUploadResult.fromDynamic(body);
          if (!parsed.success) {
            final fallback = CommonModel.fromJson(
              body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
            );
            apiMessage = fallback.message ?? 'Invoice upload failed.';
            return InvoiceUploadResult(
              success: false,
              message: apiMessage,
            );
          }
          apiMessage = parsed.message;
          return parsed;
        },
        error: (exception) {
          apiMessage = exception.message;
          return InvoiceUploadResult(
            success: false,
            message: exception.message,
          );
        },
      );
    } catch (e) {
      final errorMessage = "Unexpected Error: $e";
      Utils.instance.log(errorMessage);
      apiMessage = errorMessage;
      return InvoiceUploadResult(success: false, message: errorMessage);
    }
  }

  Future<InvoiceDeleteResult> deleteShipmentInvoiceFileRepo({
    String? invoiceFileId,
    String? fileName,
  }) async {
    apiMessage = null;

    final userData = await _localStorage.getUserLocalData();
    final token =
        userData?.messangerdetail?.token ?? userData?.customerdetail?.token;

    final id = invoiceFileId?.trim();
    final name = fileName?.trim();
    if ((id == null || id.isEmpty) && (name == null || name.isEmpty)) {
      apiMessage = 'Invoice file id or file name is required.';
      return const InvoiceDeleteResult(success: false);
    }

    try {
      final response = await _apiServices.deleteShipmentInvoiceFile(
        invoiceFileId: id,
        fileName: name,
        token: token,
      );

      return response.when(
        success: (body) {
          log("Delete invoice API success body: $body");
          final parsed = InvoiceDeleteResult.fromDynamic(
            body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
          );
          if (!parsed.success) {
            final fallback = CommonModel.fromJson(
              body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
            );
            apiMessage = fallback.message ?? 'Invoice delete failed.';
            return InvoiceDeleteResult(
              success: false,
              message: apiMessage,
            );
          }
          apiMessage = parsed.message;
          return parsed;
        },
        error: (exception) {
          apiMessage = exception.message;
          return InvoiceDeleteResult(
            success: false,
            message: exception.message,
          );
        },
      );
    } catch (e) {
      final errorMessage = "Unexpected Error: $e";
      Utils.instance.log(errorMessage);
      apiMessage = errorMessage;
      return InvoiceDeleteResult(success: false, message: errorMessage);
    }
  }
}
