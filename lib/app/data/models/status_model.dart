class StatusModel {
  final String? id;
  final String? status;

  StatusModel({this.id, this.status});

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id']?.toString(),
      status: json['status'] ?? '',
    );
  }
}
