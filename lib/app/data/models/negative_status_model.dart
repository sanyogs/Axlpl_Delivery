class NegativeStatusModel {
  final String? id;
  final String? status;
  final String? statusTitle;
  final String? statusCode;
  final String? statusCategory;

  NegativeStatusModel({
    this.id,
    this.status,
    this.statusTitle,
    this.statusCode,
    this.statusCategory,
  });

  String get displayText {
    final s = statusTitle?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final fallback = status?.trim() ?? '';
    if (fallback.isNotEmpty) return fallback;
    final code = statusCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return (id ?? '').trim();
  }

  String get apiValue {
    final s = statusTitle?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final fallback = status?.trim() ?? '';
    if (fallback.isNotEmpty) return fallback;
    final code = statusCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return (id ?? '').trim();
  }

  factory NegativeStatusModel.fromJson(Map<String, dynamic> json) {
    String? rawStatus;
    if (json.containsKey('negative_status')) {
      rawStatus = json['negative_status']?.toString();
    } else if (json.containsKey('status_title')) {
      rawStatus = json['status_title']?.toString();
    } else if (json.containsKey('status')) {
      rawStatus = json['status']?.toString();
    } else if (json.containsKey('name')) {
      rawStatus = json['name']?.toString();
    } else if (json.containsKey('title')) {
      rawStatus = json['title']?.toString();
    }

    return NegativeStatusModel(
      id: json['id']?.toString(),
      status: rawStatus?.toString() ?? '',
      statusTitle: json['status_title']?.toString(),
      statusCode: json['status_code']?.toString(),
      statusCategory: json['status_category']?.toString(),
    );
  }
}
