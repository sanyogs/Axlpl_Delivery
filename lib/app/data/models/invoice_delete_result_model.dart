class InvoiceDeleteResult {
  const InvoiceDeleteResult({
    required this.success,
    this.message,
    this.id,
    this.fileName,
  });

  final bool success;
  final String? message;
  final String? id;
  final String? fileName;

  factory InvoiceDeleteResult.fromDynamic(dynamic data) {
    if (data is! Map) {
      return const InvoiceDeleteResult(success: false);
    }
    final map = Map<String, dynamic>.from(data);
    final status = map['status']?.toString().trim().toLowerCase();
    final serverMessage = map['__server_message']?.toString();
    final inner = map['data'];
    final innerMap = inner is Map ? Map<String, dynamic>.from(inner) : null;

    final id = innerMap?['id']?.toString() ??
        map['id']?.toString();
    final fileName = innerMap?['file_name']?.toString() ??
        map['file_name']?.toString();

    if (status == 'success' ||
        (status == null && (id != null || fileName != null))) {
      return InvoiceDeleteResult(
        success: true,
        message: map['message']?.toString() ??
            serverMessage ??
            'Invoice file deleted successfully',
        id: id,
        fileName: fileName,
      );
    }

    return InvoiceDeleteResult(
      success: false,
      message: map['message']?.toString() ?? serverMessage,
      id: id,
      fileName: fileName,
    );
  }
}
