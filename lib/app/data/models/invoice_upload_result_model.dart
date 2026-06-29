class InvoiceUploadResult {
  const InvoiceUploadResult({
    required this.success,
    this.message,
    this.shipmentId,
    this.totalFilesUploaded = 0,
    this.files = const [],
  });

  final bool success;
  final String? message;
  final String? shipmentId;
  final int totalFilesUploaded;
  final List<String> files;

  factory InvoiceUploadResult.fromDynamic(dynamic data) {
    if (data is! Map) {
      return const InvoiceUploadResult(success: false);
    }
    final map = Map<String, dynamic>.from(data);
    final status = map['status']?.toString().trim().toLowerCase();
    final uploadedFiles = <String>[];
    final rawFiles = map['files'];
    if (rawFiles is List) {
      for (final item in rawFiles) {
        final name = item?.toString().trim();
        if (name != null && name.isNotEmpty) uploadedFiles.add(name);
      }
    }
    final total = map['total_files_uploaded'];
    final totalCount = total is num
        ? total.toInt()
        : int.tryParse(total?.toString() ?? '') ?? uploadedFiles.length;
    final explicitSuccess = status == 'success';
    final inferredSuccess =
        status == null && (uploadedFiles.isNotEmpty || totalCount > 0);

    return InvoiceUploadResult(
      success: explicitSuccess || inferredSuccess,
      message: map['message']?.toString() ??
          map['__server_message']?.toString(),
      shipmentId: map['shipment_id']?.toString(),
      totalFilesUploaded: totalCount,
      files: uploadedFiles,
    );
  }
}
