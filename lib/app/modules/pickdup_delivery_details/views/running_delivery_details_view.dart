import 'package:axlpl_delivery/app/data/models/status_model.dart';
import 'package:axlpl_delivery/app/data/models/negative_status_model.dart';
import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/modules/pickup/controllers/pickup_controller.dart';
import 'package:axlpl_delivery/app/modules/shipnow/controllers/shipnow_controller.dart';
import 'package:axlpl_delivery/common_widget/common_appbar.dart';
import 'package:axlpl_delivery/common_widget/common_scaffold.dart';
import 'package:axlpl_delivery/common_widget/common_textfiled.dart';
import 'package:axlpl_delivery/common_widget/invoice_image_dialog.dart';
import 'package:axlpl_delivery/common_widget/otp_dialog.dart';
import 'package:axlpl_delivery/common_widget/paginated_dropdown.dart';
import 'package:axlpl_delivery/common_widget/pickup_dialog.dart';
import 'package:axlpl_delivery/common_widget/tracking_info_widget.dart';
import 'package:axlpl_delivery/common_widget/transfer_dialog.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../controllers/running_delivery_details_controller.dart';

class RunningDeliveryDetailsView
    extends GetView<RunningDeliveryDetailsController> {
  // final RunningPickUp? runningPickUp;
  final isShowInvoice;
  final isShowTransfer;

  RunningDeliveryDetailsView({
    this.isShowInvoice = true,
    this.isShowTransfer = false,
    super.key,
    // this.runningPickUp,
  });

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;

    final String? shipmentID = args?['shipmentID']?.toString();
    final String? messengerId = args?['messangerId']?.toString();

    final String? invoicePath = args?['invoicePath'] as String?;
    // final String? enableTransfer = Get.arguments['enableTransfer'] as String?;

    final String? date = args?['date'] as String?;

    final String? invoicePhoto = args?['invoicePhoto'] as String?;

    final pickupController = Get.put(PickupController());
    controller.loadUserRole();

    void showInvoiceSourcePicker(String shipmentId) {
      showModalBottomSheet<void>(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Text(
                'Add Invoice',
                style: themes.fontSize16_400
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Icon(Icons.attach_file, color: themes.darkCyanBlue),
                title: const Text('Attach invoice'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickImage(ImageSource.gallery, (file) {
                    controller.setImage(shipmentId, file);
                  });
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: themes.darkCyanBlue),
                title: const Text('Capture using camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickImage(ImageSource.camera, (file) {
                    controller.setImage(shipmentId, file);
                  });
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      );
    }

    return CommonScaffold(
      appBar: commonAppbar('Tracking Detail'),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(child: Obx(
          () {
            final senderData = controller.senderData;
            final receiverData = controller.receiverData;
            final details = controller.shipmentDetail.value;
            print(details?.invoiceNumber.toString() ?? 'N/A');
            if (controller.isTrackingLoading.value == Status.loading) {
              return Center(
                child: CircularProgressIndicator.adaptive(),
              );
            } else if (controller.isTrackingLoading.value == Status.error) {
              return Center(
                child: Text(
                  'No Tracking Data Found',
                  style: themes.fontReboto16_600,
                ),
              );
            } else if (controller.isTrackingLoading.value == Status.success) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top container with order and status
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // CircleAvatar(
                            //   backgroundColor: themes.blueGray,
                            //   child: Image.asset(shopingIcon, width: 20.w),
                            // ),
                            // SizedBox(width: 12),
                            Text(
                              '${details?.shipmentId ?? 'N/A'}',
                              style: themes.fontSize14_500.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 12.sp),
                              overflow: TextOverflow.ellipsis,
                            ),
                            IconButton(
                                onPressed: () {
                                  Clipboard.setData(new ClipboardData(
                                      text: shipmentID.toString()));
                                },
                                icon: Icon(
                                  Icons.copy,
                                  size: 18,
                                )),
                            Spacer(),
                            Obx(() {
                              final userRole = controller.role.value;

                              return Expanded(
                                flex: 5,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: themes.blueGray,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: InkWell(
                                      onTap: userRole == "messanger"
                                          ? () {
                                        showStatusDialog(
                                          shipmentID ?? '',
                                          controller,
                                        );
                                      }
                                          : null,
                                      borderRadius: BorderRadius.circular(15),
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                        child: Text(
                                          details?.shipmentStatus.toString() ?? 'N/A',
                                          overflow: TextOverflow.fade,
                                          style: themes.fontSize14_500.copyWith(
                                            color: themes.darkCyanBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sender & Receiver Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.my_location, color: themes.darkCyanBlue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderData.isNotEmpty
                                        ? senderData[0].senderName ??
                                            'No sender name'
                                        : 'No sender name',
                                    style: themes.fontSize16_400.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${senderData.isNotEmpty ? senderData[0].address1 ?? '' : ''}, ${senderData.isNotEmpty ? senderData[0].state ?? '' : ''}',
                                    style: themes.fontSize14_400.copyWith(
                                      color: themes.grayColor,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        // Receiver
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: themes.darkCyanBlue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    receiverData.isNotEmpty
                                        ? receiverData[0].receiverName ??
                                            'No receiver name'
                                        : 'No receiver name',
                                    style: themes.fontSize16_400.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${receiverData.isNotEmpty ? receiverData[0].address1 ?? '' : ''}, ${receiverData.isNotEmpty ? receiverData[0].state ?? '' : ''}',
                                    style: themes.fontSize14_400.copyWith(
                                        color: themes.grayColor,
                                        fontSize: 13.sp),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    receiverData.isNotEmpty
                                        ? receiverData[0].mobile ?? 'N/A'
                                        : 'N/A',
                                    style: themes.fontSize14_400.copyWith(
                                        color: themes.grayColor,
                                        fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Parcel & Weight + Payment Mode Cards
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: infoCard('Parcel Details',
                                    details?.parcelDetail ?? 'N/A')),
                            SizedBox(width: 12),
                            Expanded(
                                child: infoCard('Net Weight',
                                    '${details?.netWeight ?? "N/A"}g')),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: infoCard('Gross Weight',
                                    '${details?.grossWeight ?? "N/A"}g')),
                            SizedBox(width: 12),
                            Expanded(
                                child: infoCard('Payment Mode',
                                    details?.paymentMode ?? 'N/A')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Insurance Details Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Insurance Details',
                            style: themes.fontSize16_400
                                .copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 10.h,
                        ),
                        infoRow('Insurance Value',
                            details?.insuranceValue?.toString() ?? 'N/A'),
                        Divider(),
                        SizedBox(height: 8),
                        infoRow('Insurance Charges',
                            details?.insuranceCharges?.toString() ?? 'N/A'),
                        // Divider(),
                        // SizedBox(height: 8),
                        // _infoRow('Total Charges',
                        //     details?.totalCharges?.toString() ?? 'N/A'),
                        Divider(),
                        SizedBox(height: 12),
                        infoRow(
                          'Insurance Type',
                          details?.axlplInsurance == '1'
                              ? 'Yes Axlpl Insurance'
                              : 'No Axlpl Insurance',
                        ),
                        Divider(),
                        SizedBox(height: 8),
                        infoRow(
                          'Policy Details',
                          details?.policyNo?.isEmpty == true
                              ? 'No Policy'
                              : details?.policyNo ?? '',
                        ),
                        // SizedBox(height: 15.h),
                        // Divider(),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Charges Details',
                            style: themes.fontSize16_400
                                .copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 10.h,
                        ),
                        infoRow('Gst ', details?.tax?.toString() ?? 'N/A'),
                        Divider(),
                        SizedBox(height: 8),
                        infoRow('Total Charges',
                            details?.totalCharges?.toString() ?? 'N/A'),
                        // Divider(),
                        // SizedBox(height: 8),
                        // _infoRow('Total Charges',
                        //     details?.totalCharges?.toString() ?? 'N/A'),
                        Divider(),
                        SizedBox(height: 8),
                        infoRow('Grand Total',
                            details?.grandTotal?.toString() ?? 'N/A'),
                        // SizedBox(height: 15.h), c c
                        // Divider(),
                      ],
                    ),
                  ),
                  controller.hasCashCollectionData
                      ? Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themes.whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Collection Details',
                                  style: themes.fontSize16_400
                                      .copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10.h),
                              Column(
                                children: [
                                  ...controller.cashCollectionData
                                      .map((cashLog) {
                                    return Column(
                                      children: [
                                        infoRow(
                                            'Collected Date',
                                            DateFormat('dd MMM yy')
                                                .format(cashLog.createdDate!)),
                                        Divider(),
                                        SizedBox(height: 6),
                                        infoRow('Payment Mode',
                                            cashLog.subPaymentMode ?? 'N/A'),
                                        Divider(),
                                        SizedBox(height: 6),
                                        infoRow('Collected By',
                                            cashLog.colletedBy ?? 'N/A'),
                                        Divider(),
                                        SizedBox(height: 6),
                                        infoRow('Collected Amount',
                                            '₹${cashLog.cashamount?.toString() ?? cashLog.amount?.toString() ?? 'N/A'}'),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              )
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                  isShowInvoice == true
                      ? Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themes.whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text('Invoice Details',
                                  style: themes.fontSize16_400
                                      .copyWith(fontWeight: FontWeight.bold)),
                              infoRow('Invoice Value',
                                  details?.invoiceValue?.toString() ?? 'N/A'),
                              Divider(),
                              SizedBox(height: 8),
                              infoRow(
                                'Invoice Number',
                                details?.invoiceNumber.toString() ?? 'N/A',
                              ),
                              // Divider(),
                              // SizedBox(height: 8),
                              // infoRow(
                              //     'Invoice Charges',
                              //     details?.invoiceCharges?.toString() == ''
                              //         ? 'N/A'
                              //         : '' ?? 'N/A'),
                              Divider(),
                              (details?.invoiceFile ?? '').isNotEmpty
                                  ? InvoiceImagePopup(
                                      invoicePath:
                                          details?.invoicePath.toString() ??
                                              invoicePath ??
                                              '',
                                      invoicePhoto:
                                          details?.invoiceFile.toString() ??
                                              invoicePhoto ??
                                              '',
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 8.h),
                                        Obx(() {
                                          final file = controller
                                              .getImage(shipmentID.toString());

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (file ==
                                                  null) // No image selected, show upload icon
                                                InkWell(
                                                  onTap: () {
                                                    showInvoiceSourcePicker(
                                                      shipmentID.toString(),
                                                    );
                                                  },
                                                  child: Icon(
                                                    Icons.upload_file,
                                                    color: themes.darkCyanBlue,
                                                    size: 40.sp,
                                                  ),
                                                )
                                              else // Image selected, show preview with remove button
                                                Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.file(
                                                        file,
                                                        width: 120,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 4,
                                                      right: 4,
                                                      child: GestureDetector(
                                                        onTap: () => controller
                                                            .removeImage(
                                                                shipmentID
                                                                    .toString()),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black54,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          padding:
                                                              EdgeInsets.all(4),
                                                          child: Icon(
                                                            Icons.close,
                                                            size: 20,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      themes.darkCyanBlue,
                                                  foregroundColor:
                                                      themes.whiteColor,
                                                ),
                                                onPressed: file == null
                                                    ? null
                                                    : () {
                                                        controller
                                                            .uploadInvoice(
                                                          shipmentID: details
                                                                  ?.shipmentId
                                                                  .toString() ??
                                                              '0',
                                                          file: file,
                                                        );
                                                      },
                                                child: Text('UPLOAD'),
                                              ),
                                            ],
                                          );
                                        }),
                                        // SizedBox(height: 12.h),
                                        // Obx(() {
                                        //   final file = controller
                                        //       .getImage(shipmentID.toString());
                                        //   if (file == null) return SizedBox();

                                        //   return Stack(
                                        //     children: [
                                        //       ClipRRect(
                                        //         borderRadius:
                                        //             BorderRadius.circular(8),
                                        //         child: Image.file(file,
                                        //             width: 120,
                                        //             height: 120,
                                        //             fit: BoxFit.cover),
                                        //       ),
                                        //       Positioned(
                                        //         top: 4,
                                        //         right: 4,
                                        //         child: GestureDetector(
                                        //           onTap: () => controller
                                        //               .removeImage(shipmentID
                                        //                   .toString()),
                                        //           child: Container(
                                        //             decoration: BoxDecoration(
                                        //                 color: Colors.black54,
                                        //                 shape: BoxShape.circle),
                                        //             child: Icon(Icons.close,
                                        //                 size: 20,
                                        //                 color: Colors.white),
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   );
                                        // }),
                                      ],
                                    ),
                            ],
                          ),
                        )
                      : SizedBox(),
                  isShowTransfer
                      ? Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: themes.whiteColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(
                                  () {
                                    final userId =
                                        pickupController.currentUserId.value;
                                    final enableTransfer =
                                        messengerId.toString() == userId;
                                    return ElevatedButton(
                                      onPressed: enableTransfer
                                          ? () {
                                              showTransferDialog(
                                                () {
                                                  final messengerId =
                                                      pickupController
                                                          .selectedMessenger
                                                          .value
                                                          .toString();
                                                  if (messengerId.isNotEmpty) {
                                                    pickupController
                                                        .transferShipment(
                                                      shipmentID.toString(),
                                                      messengerId, // Pass selected messenger ID
                                                    );
                                                    Get.back();
                                                  } else {
                                                    Get.snackbar(
                                                      'Error',
                                                      'Please select a messenger',
                                                      colorText:
                                                          themes.whiteColor,
                                                      backgroundColor:
                                                          themes.redColor,
                                                    );
                                                    Get.back();
                                                  }
                                                },
                                              );
                                            }
                                          : null,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: enableTransfer
                                            ? themes.whiteColor
                                            : themes.blueGray,
                                        foregroundColor: enableTransfer
                                            ? themes.darkCyanBlue
                                            : themes.grayColor,
                                        side: BorderSide(
                                            color: enableTransfer
                                                ? themes.darkCyanBlue
                                                : themes.grayColor,
                                            width: 1.w),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20.w, vertical: 8.h),
                                      ),
                                      child: Text(
                                        'Transfer',
                                        style: themes.fontSize18_600.copyWith(
                                          fontSize: 14.sp,
                                          color: enableTransfer
                                              ? themes.darkCyanBlue
                                              : themes.grayColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final amountController =
                                        pickupController.getAmountController(
                                            shipmentID.toString());
                                    final chequeController =
                                        pickupController.getChequeController(
                                            shipmentID.toString());
                                    final otpController =
                                        pickupController.getOtpController(
                                            shipmentID.toString());
                                    final selectedSubPaymentMode =
                                        pickupController
                                            .getSelectedSubPaymentMode(
                                                shipmentID.toString());

                                    if (details?.paymentMode.toString() !=
                                        'topay') {
                                      showOtpDialog(
                                        () async {
                                          pickupController.uploadPickup(
                                            shipmentID,
                                            'Picked up',
                                            date,
                                            amountController.text,
                                            details?.paymentMode.toString() ??
                                                'N/A',
                                            selectedSubPaymentMode.value?.id,
                                            otpController.text,
                                          );
                                        },
                                        () async {
                                          await pickupController
                                              .getOtp(shipmentID);
                                        },
                                        otpController,
                                      );
                                    } else {
                                      showPickupDialog(
                                        shipmentID: shipmentID,
                                        date: date,
                                        amt: details?.totalCharges,
                                        dropdownHintTxt: selectedSubPaymentMode
                                                .value?.name ??
                                            'Select Payment Mode',
                                        btnTxt: 'Pickup',
                                        amountController: amountController,
                                        chequeNumberController:
                                            chequeController,
                                        otpController: otpController,
                                        selectedSubPaymentMode:
                                            selectedSubPaymentMode,
                                        onConfirmCallback: () {
                                          pickupController.uploadPickup(
                                            shipmentID,
                                            'Picked up',
                                            date,
                                            amountController.text,
                                            details?.paymentMode.toString() ??
                                                'N/A',
                                            selectedSubPaymentMode.value?.id,
                                            otpController.text,
                                            chequeNumber: chequeController.text,
                                          );
                                        },
                                        onSendOtpCallback: () async {
                                          await pickupController
                                              .getOtp(shipmentID);
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: themes.whiteColor,
                                    backgroundColor: themes.darkCyanBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 30.w, vertical: 8.h),
                                  ),
                                  child: Text('Pickup',
                                      style: TextStyle(fontSize: 13.sp)),
                                )
                              ],
                            ),
                          ),
                        )
                      : SizedBox(),
                  // Your stepper container remains unchanged

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themes.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipment Status',
                            style: themes.fontSize16_400.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Custom Stepper using step_progress_indicator
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: controller.trackingStatus.length,
                            itemBuilder: (context, index) {
                              final step = controller.trackingStatus[index];
                              final isLast =
                                  index == controller.trackingStatus.length - 1;
                              String stepFormattedDate =
                                  DateFormat('dd MMM yy').format(step.dateTime);

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Step indicator column
                                  Column(
                                    children: [
                                      // Step circle
                                      Container(
                                        width: 35.w,
                                        height: 35.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: themes.blueGray,
                                        ),
                                        child: Icon(
                                          Icons.gps_fixed,
                                          color: themes.darkCyanBlue,
                                          size: 20.sp,
                                        ),
                                      ),
                                      // Connecting line (if not last item)
                                      if (!isLast)
                                        Container(
                                          width: 2.w,
                                          height: 35.h,
                                          color: themes.blueGray,
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: 16.w),
                                  // Content column
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  step.status,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                stepFormattedDate,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!isLast) SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                ],
              );
            } else {
              return Center(
                child: Text('No Track Data Found!'),
              );
            }
          },
        )),
      ),
    );
  }
}

Widget buildDetailSection(String title, String mainInfo, String secondaryInfo,
        {String? extraInfo}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: themes.fontSize18_600
                .copyWith(color: themes.grayColor, fontSize: 16.sp)),
        SizedBox(height: 4),
        Text(mainInfo, style: themes.fontSize14_500.copyWith(fontSize: 15.sp)),
        if (secondaryInfo.trim().isNotEmpty)
          Text(secondaryInfo,
              style: themes.fontSize14_500.copyWith(color: themes.grayColor)),
        if (extraInfo != null)
          Text(extraInfo,
              style: themes.fontSize14_500.copyWith(color: themes.grayColor)),
      ],
    );

void showStatusDialog(
    String shipmentId,
    RunningDeliveryDetailsController controller,
    ) async {
  // ✅ Fetch the latest statuses
  await controller.getAllStatuses();
  await controller.getNegativeStatuses();

  // ✅ Reset the selected value safely
  controller.isNegative.value = false;
  controller.selectedNegativeStatus.value = null;
  controller.negativeRemarkController.clear();
  controller.receiverNameController.clear();
  controller.setSelectedStatus(null);

  // ✅ Access the shipnowController for refresh
  final shipnowController = Get.find<ShipnowController>();

  // ✅ Use Get.dialog for custom layout
  Get.dialog(
    Material(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: Get.width * 0.85, // adds left-right margins
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: themes.whiteColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Title
                Text(
                  "Shipment Status",
                  style: themes.fontSize18_600.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Status History
                Obx(() {
                  final history = controller.trackingStatus;
                  final last = history.isNotEmpty && history.last is TrackingStatus
                      ? history.last as TrackingStatus
                      : null;
                  final statusText = last?.status ?? 'N/A';
                  final dateText = last?.dateTime != null
                      ? DateFormat('dd-MM-yyyy h:mm a')
                          .format(last!.dateTime!)
                          .toLowerCase()
                      : 'N/A';

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status History',
                          style: themes.fontSize14_500
                              .copyWith(color: themes.darkCyanBlue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status : $statusText',
                          style: themes.fontSize14_500,
                        ),
                        Text(
                          'Date : $dateText',
                          style: themes.fontSize14_500,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Change Status',
                    style: themes.fontSize14_500
                        .copyWith(color: themes.darkCyanBlue),
                  ),
                ),
                const SizedBox(height: 6),

                // Dropdown Section
                Obx(() {
                  final list = controller.statusList;

                  if (controller.isStatusUpdating.value) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }

                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  return DropdownButtonFormField<StatusModel>(
                    isExpanded: true,
                    value: controller.selectedStatus.value,
                    items: list.map((status) {
                      return DropdownMenuItem<StatusModel>(
                        value: status,
                        child: Text(status.status ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      controller.setSelectedStatus(value);
                    },
                    decoration: const InputDecoration(
                      hintText: "Select Status",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  );
                }),

                const SizedBox(height: 14),

                // Exception Checkbox
                Obx(() {
                  return Row(
                    children: [
                      Checkbox(
                        value: controller.isNegative.value,
                        onChanged: (value) {
                          final flag = value ?? false;
                          controller.isNegative.value = flag;
                          if (!flag) {
                            controller.selectedNegativeStatus.value = null;
                          }
                        },
                        activeColor: themes.darkCyanBlue,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        'Is Exception?',
                        style: themes.fontSize14_500
                            .copyWith(color: themes.darkCyanBlue),
                      ),
                    ],
                  );
                }),

                // Negative Status
                Obx(() {
                  if (!controller.isNegative.value) {
                    return const SizedBox.shrink();
                  }

                  if (controller.isNegativeStatusLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    );
                  }

                  final negativeList = controller.negativeStatusList;

                  if (negativeList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No negative statuses found',
                        style: themes.fontSize14_500
                            .copyWith(color: themes.grayColor),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Negative Status',
                        style: themes.fontSize14_500
                            .copyWith(color: themes.darkCyanBlue),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<NegativeStatusModel>(
                        isExpanded: true,
                        value: controller.selectedNegativeStatus.value,
                        items: negativeList.map((status) {
                          return DropdownMenuItem<NegativeStatusModel>(
                            value: status,
                            child: Text(
                              status.displayText.isNotEmpty
                                  ? status.displayText
                                  : 'Unknown',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          controller.selectedNegativeStatus.value = value;
                        },
                        decoration: const InputDecoration(
                          hintText: "Select",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                // Remark (optional unless exception)
                CommonTextfiled(
                  controller: controller.negativeRemarkController,
                  obscureText: false,
                  hintTxt: 'Remark',
                  lableText: 'Remark',
                  keyboardType: TextInputType.text,
                  maxLine: 2,
                ),

                // Receiver Name (only for Delivered)
                Obx(() {
                  final statusText = (controller.selectedStatus.value?.status ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
                  final isDelivered = statusText == 'delivered';
                  if (!isDelivered) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: CommonTextfiled(
                      controller: controller.receiverNameController,
                      obscureText: false,
                      hintTxt: 'Receiver Name',
                      lableText: 'Receiver Name',
                      keyboardType: TextInputType.text,
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Buttons Section
                Obx(() {
                  final isLoading = controller.isStatusUpdating.value;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Confirm Button
                      TextButton(
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: themes.darkCyanBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                          // ✅ Perform the update
                          final success = await controller.updateShipmentStatus(shipmentId);

                          if (success) {
                            Get.back();
                            // ✅ Refresh the shipment list after success
                            await shipnowController.refreshData();
                          }
                        },
                        child: isLoading
                            ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "Update",
                          style: themes.fontSize14_500
                              .copyWith(color: themes.whiteColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Cancel Button
                      TextButton(
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: themes.darkCyanBlue, width: 2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel",
                          style: themes.fontSize14_500.copyWith(color: themes.darkCyanBlue),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
