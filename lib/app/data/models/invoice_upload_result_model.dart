import 'package:axlpl_delivery/app/data/models/tracking_model.dart';

class InvoiceUploadResult {
  const InvoiceUploadResult({
    required this.success,
    this.message,
    this.shipmentId,
    this.totalFilesUploaded = 0,
    this.uploadedInvoiceFiles = const [],
  });

  final bool success;
  final String? message;
  final String? shipmentId;
  final int totalFilesUploaded;
  final List<ShipmentInvoiceFile> uploadedInvoiceFiles;

  List<String> get files => uploadedInvoiceFiles
      .map((file) => file.fileName?.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  factory InvoiceUploadResult.fromDynamic(dynamic data) {
    if (data is! Map) {
      return const InvoiceUploadResult(success: false);
    }
    final map = Map<String, dynamic>.from(data);
    final status = map['status']?.toString().trim().toLowerCase();
    final parsedFiles = <ShipmentInvoiceFile>[];
    _parseUploadFilesInto(parsedFiles, map['files']);
    final nested = map['data'];
    if (nested is Map) {
      _parseUploadFilesInto(
        parsedFiles,
        Map<String, dynamic>.from(nested)['files'],
      );
    }
    final total = map['total_files_uploaded'];
    final totalCount = total is num
        ? total.toInt()
        : int.tryParse(total?.toString() ?? '') ?? parsedFiles.length;
    final explicitSuccess = status == 'success';
    final inferredSuccess =
        status == null && (parsedFiles.isNotEmpty || totalCount > 0);

    return InvoiceUploadResult(
      success: explicitSuccess || inferredSuccess,
      message: map['message']?.toString() ??
          map['__server_message']?.toString(),
      shipmentId: map['shipment_id']?.toString(),
      totalFilesUploaded: totalCount,
      uploadedInvoiceFiles: parsedFiles,
    );
  }

  static void _parseUploadFilesInto(
    List<ShipmentInvoiceFile> out,
    dynamic rawFiles,
  ) {
    if (rawFiles is! List) return;
    final seen = <String>{
      for (final file in out)
        if (file.fileName?.trim().isNotEmpty == true) file.fileName!.trim(),
    };
    for (final item in rawFiles) {
      final file = _parseUploadFileEntry(item);
      final name = file?.fileName?.trim();
      if (file == null || name == null || name.isEmpty || seen.contains(name)) {
        continue;
      }
      seen.add(name);
      out.add(file);
    }
  }

  static ShipmentInvoiceFile? _parseUploadFileEntry(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      return ShipmentInvoiceFile.fromJson(Map<String, dynamic>.from(item));
    }
    final name = item.toString().trim();
    if (name.isEmpty) return null;
    return ShipmentInvoiceFile(fileName: name);
  }
}
