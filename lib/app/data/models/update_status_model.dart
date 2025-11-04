class UpdateStatusModel {
  final String? status;
  final String? message;
  final String? shipmentId;
  final String? statusText;

  UpdateStatusModel({
    this.status,
    this.message,
    this.shipmentId,
    this.statusText,
  });

  factory UpdateStatusModel.fromJson(Map<String, dynamic> json) {
    return UpdateStatusModel(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      shipmentId: json['shipment_id']?.toString(),
      statusText: json['status_text']?.toString(),
    );
  }
}

