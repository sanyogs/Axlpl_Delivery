import 'dart:developer';
import 'dart:io';

import 'package:axlpl_delivery/app/data/models/shipment_record_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/common_widget/common_appbar.dart';
import 'package:axlpl_delivery/common_widget/common_button.dart';
import 'package:axlpl_delivery/common_widget/common_scaffold.dart';
import 'package:axlpl_delivery/common_widget/container_textfiled.dart';
import 'package:axlpl_delivery/common_widget/image_picker_widget.dart';
import 'package:axlpl_delivery/utils/assets.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/pod_controller.dart';

class PodView extends GetView<PodController> {
  const PodView({super.key});
  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
        appBar: commonAppbar('Upload POD'),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
              children: [
                Platform.isIOS
                    ? SizedBox(
                        height: 2.h,
                      )
                    : SizedBox.shrink(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ContainerTextfiled(
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: themes.grayColor,
                        ),
                        hintText: 'Shipment ID',
                        controller: controller.shipmentIdController,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        var scannedValue =
                            await Utils().scanAndPlaySound(context);
                        if (scannedValue != null && scannedValue != '-1') {
                          controller.shipmentIdController.text = scannedValue;
                          log(scannedValue.toString());
                        }
                        // String? res = await SimpleBarcodeScanner.scanBarcode(
                        //   scanType: ScanType.defaultMode,
                        //   context,
                        //   barcodeAppBar: const BarcodeAppBar(
                        //     appBarTitle: '',
                        //     centerTitle: false,
                        //     enableBackButton: true,
                        //     backButtonIcon: Icon(Icons.arrow_back_ios),
                        //   ),
                        //   isShowFlashIcon: true,
                        //   cameraFace: CameraFace.back,
                        // );

                        // if (res != null && res != "-1") {
                        //   controller.shipmentIdController.text = res;
                        //   log("Scanned result: $res");
                        // } else {
                        //   log("Scan cancelled or failed.");
                        // }
                      },
                      icon: Icon(CupertinoIcons.qrcode_viewfinder),
                    )
                  ],
                ),
                Obx(() {
                  final lookupStatus = controller.isShipmentRecord.value;
                  final lookupMessage = controller.shipmentLookupMessage.value;
                  final shipment = controller.shipmentRecordList.isNotEmpty
                      ? controller.shipmentRecordList.first
                      : null;

                  if (lookupStatus == Status.initial &&
                      shipment == null &&
                      lookupMessage.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (lookupStatus == Status.loading)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Fetching shipment…',
                                style: themes.fontSize14_400.copyWith(
                                  color: themes.grayColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (shipment != null) ...[
                        SizedBox(height: 12.h),
                        _ShipmentPreviewCard(
                          shipment: shipment,
                          fallbackShipmentId:
                              controller.shipmentIdController.text.trim(),
                        ),
                      ],
                      if (lookupMessage.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: lookupStatus == Status.error
                                ? themes.redColor.withOpacity(0.08)
                                : themes.darkCyanBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: lookupStatus == Status.error
                                  ? themes.redColor.withOpacity(0.25)
                                  : themes.darkCyanBlue.withOpacity(0.18),
                              width: 1.w,
                            ),
                          ),
                          child: Text(
                            lookupMessage,
                            style: themes.fontSize14_400.copyWith(
                              color: lookupStatus == Status.error
                                  ? themes.redColor
                                  : themes.darkCyanBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
                DottedBorder(
                  borderType: BorderType.RRect,
                  dashPattern: [8, 4],
                  radius: Radius.circular(10.r),
                  padding: EdgeInsets.all(2),
                  color: themes.blueColor,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: themes.blueGray,
                        borderRadius: BorderRadius.circular(10.r)),
                    child: Padding(
                        padding: const EdgeInsets.all(38.0).r,
                        child: Obx(
                          () {
                            if (controller.imageFile.value == null) {
                              return InkWell(
                                onTap: () {
                                  if (controller
                                      .shipmentIdController.text.isNotEmpty) {
                                    pickImage(ImageSource.camera,
                                        controller.imageFile);
                                  } else {
                                    Get.snackbar(
                                      'error',
                                      'Shipment ID Required!',
                                      colorText: themes.whiteColor,
                                      backgroundColor: themes.redColor,
                                    );
                                  }
                                },
                                child: Column(
                                  children: [
                                    Image.asset(
                                      uploadIcon,
                                      width: 40.w,
                                    ),
                                    Text(
                                      'Upload your file here',
                                      style: themes.fontSize14_500,
                                    )
                                  ],
                                ),
                              );
                            } else {
                              return Stack(
                                  fit: StackFit.loose,
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Image.file(
                                        // width: 60.w,
                                        height: 150.h,
                                        File(
                                          controller.imageFile.value!.path,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 5,
                                      left: 160,
                                      child: IconButton(
                                        iconSize: 30,
                                        onPressed: () {
                                          controller.imageFile.value = null;
                                        },
                                        icon: Icon(Icons.cancel),
                                      ),
                                    ),
                                  ]);
                            }
                          },
                        )),
                  ),
                ),
                /*
                Obx(
                  () => CommonDropdown<Map>(
                    hint: 'Select Payment Type',
                    selectedValue: controller.selectedPaymentTypeId.value,
                    isLoading: false,
                    items: controller.paymentTypes,
                    itemLabel: (m) => m['name'] ?? '',
                    itemValue: (m) => m['id'],
                    onChanged: (val) {
                      log(val.toString());
                      controller.selectedPaymentTypeId.value = val;
                    },
                  ),
                ),*/
                // Obx(() {
                //   final toPay = controller.shipmentRecordList.any(
                //     (item) => item.paymentMode?.toLowerCase() == 'topay',
                //   );
                //   if (pickupController.isLoadingPayment.value) {
                //     return Center(
                //       child: CircularProgressIndicator.adaptive(),
                //     );
                //   } else if (toPay) {
                //     return Container(
                //       padding:
                //           EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                //       decoration: BoxDecoration(
                //         borderRadius: BorderRadius.circular(12),
                //         border:
                //             Border.all(color: Colors.grey.shade400, width: 1),
                //         color: Colors.white,
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.grey.shade200,
                //             blurRadius: 6,
                //             offset: Offset(0, 2),
                //           ),
                //         ],
                //       ),
                //       child: DropdownButtonHideUnderline(
                //         child: DropdownButton<PaymentMode>(
                //           isExpanded: true,
                //           hint: Text(
                //             'Select Payment Mode',
                //             style: TextStyle(color: Colors.grey.shade600),
                //           ),
                //           value: pickupController.selectedPaymentMode.value,
                //           icon: Icon(Icons.arrow_drop_down,
                //               color: Colors.blueGrey),
                //           items: pickupController.paymentModes.map((mode) {
                //             return DropdownMenuItem<PaymentMode>(
                //               value: mode,
                //               child: Text(
                //                 mode.name,
                //                 style: TextStyle(fontSize: 16),
                //               ),
                //             );
                //           }).toList(),
                //           onChanged: (PaymentMode? newValue) {
                //             pickupController.setSelectedPaymentMode(newValue);
                //           },
                //         ),
                //       ),
                //     );
                //   } else {
                //     return SizedBox.shrink();
                //   }
                // }),
                Obx(() {
                  final isUploading = controller.isPod.value == Status.loading;
                  return CommonButton(
                    title: 'Upload',
                    isLoading: isUploading,
                    onPressed: isUploading
                        ? null
                        : () async {
                            if (controller.imageFile.value == null) {
                              Utils().showTopNotification(
                                title: 'Failed',
                                message: 'Please upload your file here',
                                isError: true,
                              );
                              return;
                            }

                            controller.uploadPod(
                              shipmentStatus: 'Delivered',
                              shipmentOtp: '0000',
                              file: File(controller.imageFile.value!.path),
                            );
                          },
                  );
                })
              ],
            ),
          ),
        ));
  }
}

class _ShipmentPreviewCard extends StatelessWidget {
  const _ShipmentPreviewCard({
    required this.shipment,
    required this.fallbackShipmentId,
  });

  final ShipmentRecordList shipment;
  final String fallbackShipmentId;

  Color _statusColor(String? status) {
    final value = status?.trim().toLowerCase() ?? '';
    if (value == 'approved') return Colors.green;
    if (value == 'pending') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final status = shipment.shipmentStatus ?? 'Unknown';
    final statusColor = _statusColor(status);
    final createdDate = shipment.createdDate;
    final shipmentId = shipment.sId?.trim().isNotEmpty == true
        ? shipment.sId!.trim()
        : fallbackShipmentId;

    final origin = (shipment.senderCityname?.trim().isNotEmpty == true
            ? shipment.senderCityname!.trim()
            : shipment.senderAreaname?.trim()) ??
        '';
    final destination = (shipment.receiverCityname?.trim().isNotEmpty == true
            ? shipment.receiverCityname!.trim()
            : shipment.receiverAreaname?.trim()) ??
        '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: themes.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: themes.darkCyanBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14.sp,
                        color: themes.darkCyanBlue,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        createdDate != null
                            ? DateFormat('dd MMM yy').format(createdDate)
                            : 'N/A',
                        style: themes.fontSize14_500.copyWith(
                          color: themes.darkCyanBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        status,
                        style: themes.fontSize14_500.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18.sp,
                  color: themes.darkCyanBlue,
                ),
                SizedBox(width: 8.w),
                Text(
                  "ID: ",
                  style: themes.fontSize14_400.copyWith(
                    color: themes.grayColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    shipmentId.isNotEmpty ? shipmentId : 'N/A',
                    style: themes.fontSize14_500.copyWith(
                      color: themes.blackColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business,
                          size: 14.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "From",
                              style: themes.fontSize14_400.copyWith(
                                color: themes.grayColor,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              shipment.senderCompanyName?.trim().isNotEmpty ==
                                      true
                                  ? shipment.senderCompanyName!.trim()
                                  : 'N/A',
                              style: themes.fontSize14_500.copyWith(
                                color: themes.blackColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (shipment.senderAreaname?.trim().isNotEmpty ==
                                true)
                              Text(
                                shipment.senderAreaname!.trim(),
                                style: themes.fontSize14_400.copyWith(
                                  color: themes.grayColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[300]),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 16.sp,
                          color: themes.darkCyanBlue,
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[300]),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "To",
                              style: themes.fontSize14_400.copyWith(
                                color: themes.grayColor,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              shipment.receiverCompanyName?.trim().isNotEmpty ==
                                      true
                                  ? shipment.receiverCompanyName!.trim()
                                  : 'N/A',
                              style: themes.fontSize14_500.copyWith(
                                color: themes.blackColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (shipment.receiverAreaname?.trim().isNotEmpty ==
                                true)
                              Text(
                                shipment.receiverAreaname!.trim(),
                                style: themes.fontSize14_400.copyWith(
                                  color: themes.grayColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (origin.isNotEmpty || destination.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: themes.darkCyanBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: themes.darkCyanBlue.withOpacity(0.1),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 16.sp,
                      color: themes.darkCyanBlue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        destination.isNotEmpty
                            ? '$origin${origin.isNotEmpty ? ' → ' : ''}$destination'
                            : origin,
                        style: themes.fontSize14_500.copyWith(
                          color: themes.darkCyanBlue,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
