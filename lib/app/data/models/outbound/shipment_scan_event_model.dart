import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `getshipmentscanhistory` (raw JSON array).
class ShipmentScanEvent {
  const ShipmentScanEvent({
    this.id,
    this.shipmentId,
    this.status,
    this.isException,
    this.branchId,
    this.createdBy,
    this.uType,
    this.remark,
    this.createdDate,
    this.modifiedDate,
    this.sequenceNo,
    this.isNegative,
    this.negativeRemark,
    this.receiverName,
  });

  final String? id;
  final String? shipmentId;
  final String? status;
  final bool? isException;
  final String? branchId;
  final String? createdBy;
  final String? uType;
  final String? remark;
  final String? createdDate;
  final String? modifiedDate;
  final String? sequenceNo;
  final bool? isNegative;
  final String? negativeRemark;
  final String? receiverName;

  factory ShipmentScanEvent.fromJson(Map<String, dynamic> json) {
    return ShipmentScanEvent(
      id: OutboundDataParse.optionalString(json, 'id'),
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        's_id',
        'docket_no',
        'shipment_id',
        'consignment_no',
      ]),
      status: OutboundDataParse.optionalString(json, 'status'),
      isException: OutboundDataParse.boolFromZeroOne(json, 'is_exception'),
      branchId: OutboundDataParse.optionalString(json, 'branch_id'),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      uType: OutboundDataParse.optionalString(json, 'u_type'),
      remark: OutboundDataParse.optionalString(json, 'remark'),
      createdDate: OutboundDataParse.firstNonEmptyString(json, const [
        'created_date',
        'scanned_at',
        'created_at',
      ]),
      modifiedDate: OutboundDataParse.firstNonEmptyString(json, const [
        'modified_date',
        'updated_at',
      ]),
      sequenceNo: OutboundDataParse.optionalString(json, 'sequence_no'),
      isNegative: OutboundDataParse.boolFromZeroOne(json, 'is_negative'),
      negativeRemark: OutboundDataParse.optionalString(json, 'negative_remark'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (shipmentId != null) 's_id': shipmentId,
        if (status != null) 'status': status,
        if (isException != null) 'is_exception': isException! ? '1' : '0',
        if (branchId != null) 'branch_id': branchId,
        if (createdBy != null) 'created_by': createdBy,
        if (uType != null) 'u_type': uType,
        if (remark != null) 'remark': remark,
        if (createdDate != null) 'created_date': createdDate,
        if (modifiedDate != null) 'modified_date': modifiedDate,
        if (sequenceNo != null) 'sequence_no': sequenceNo,
        if (isNegative != null) 'is_negative': isNegative! ? '1' : '0',
        if (negativeRemark != null) 'negative_remark': negativeRemark,
        if (receiverName != null) 'receiver_name': receiverName,
      };

  static List<ShipmentScanEvent> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, ShipmentScanEvent.fromJson);
}
