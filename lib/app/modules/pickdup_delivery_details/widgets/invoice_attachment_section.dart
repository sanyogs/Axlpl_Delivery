import 'dart:io';

import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/modules/pickdup_delivery_details/controllers/running_delivery_details_controller.dart';
import 'package:axlpl_delivery/app/modules/pickdup_delivery_details/invoice_attachment_state.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

typedef InvoiceSourcePicker = void Function(String shipmentId);

/// Bottom sheet + thumbnail strip for up to 3 invoice attachments.
class InvoiceAttachmentSection extends StatelessWidget {
  const InvoiceAttachmentSection({
    super.key,
    required this.controller,
    required this.shipmentId,
    required this.onUpload,
    required this.showSourcePicker,
  });

  final RunningDeliveryDetailsController controller;
  final String shipmentId;
  final VoidCallback onUpload;
  final InvoiceSourcePicker showSourcePicker;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final files = controller.getImages(shipmentId);
      final remaining = controller.remainingAttachmentSlots(shipmentId);
      final uploading =
          controller.isInvoiceUpload.value == Status.loading;
      final max = InvoiceAttachmentState.maxInvoiceAttachments;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attachments',
                style: themes.fontSize14_500.copyWith(
                  color: themes.darkCyanBlue,
                ),
              ),
              Text(
                '${files.length}/$max',
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (files.isEmpty)
            InkWell(
              onTap: uploading ? null : () => showSourcePicker(shipmentId),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  color: themes.lightGrayColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: themes.grayColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      color: themes.darkCyanBlue,
                      size: 40.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Add invoice (up to $max)',
                      style: themes.fontSize14_400.copyWith(
                        color: themes.grayColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 112.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length + (remaining > 0 ? 1 : 0),
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, index) {
                  if (index < files.length) {
                    return _AttachmentThumb(
                      file: files[index],
                      onRemove: uploading
                          ? null
                          : () => controller.removeImage(shipmentId, index),
                    );
                  }
                  return _AddAttachmentTile(
                    onTap: uploading
                        ? null
                        : () => showSourcePicker(shipmentId),
                    remaining: remaining,
                  );
                },
              ),
            ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themes.darkCyanBlue,
                foregroundColor: themes.whiteColor,
                disabledBackgroundColor:
                    themes.grayColor.withValues(alpha: 0.35),
              ),
              onPressed: files.isEmpty || uploading ? null : onUpload,
              child: uploading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: themes.whiteColor,
                      ),
                    )
                  : Text(
                      files.length > 1
                          ? 'UPLOAD (${files.length})'
                          : 'UPLOAD',
                    ),
            ),
          ),
        ],
      );
    });
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.file(
            file,
            width: 100.w,
            height: 100.w,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.close,
                  size: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  const _AddAttachmentTile({
    required this.onTap,
    required this.remaining,
  });

  final VoidCallback? onTap;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: themes.lightGrayColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: themes.darkCyanBlue.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: themes.darkCyanBlue, size: 28.sp),
            SizedBox(height: 4.h),
            Text(
              '+$remaining',
              style: themes.fontSize14_400.copyWith(
                fontSize: 11.sp,
                color: themes.grayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showInvoiceSourcePickerSheet({
  required BuildContext context,
  required RunningDeliveryDetailsController controller,
  required String shipmentId,
}) {
  if (!controller.canAddMoreAttachments(shipmentId)) {
    Get.snackbar(
      'Invoice',
      'You can attach up to ${InvoiceAttachmentState.maxInvoiceAttachments} invoice files.',
      backgroundColor: themes.redColor,
      colorText: themes.whiteColor,
    );
    return;
  }

  final remaining = controller.remainingAttachmentSlots(shipmentId);

  showModalBottomSheet<void>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Invoice',
              textAlign: TextAlign.center,
              style: themes.fontSize16_400.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '$remaining of ${InvoiceAttachmentState.maxInvoiceAttachments} slots remaining',
              textAlign: TextAlign.center,
              style: themes.fontSize14_400.copyWith(
                fontSize: 12.sp,
                color: themes.grayColor,
              ),
            ),
            SizedBox(height: 8.h),
            _SourceTile(
              title: 'Attach invoice',
              subtitle: 'Select up to $remaining from gallery',
              icon: Icons.attach_file,
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickImagesFromGallery(shipmentId);
              },
            ),
            _SourceTile(
              title: 'Capture using camera',
              subtitle: 'Take a photo',
              icon: Icons.camera_alt_outlined,
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickImage(ImageSource.camera, (file) {
                  controller.addImage(shipmentId, file);
                });
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: themes.whiteColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: themes.fontSize14_500),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: themes.fontSize14_400.copyWith(
                        fontSize: 11.sp,
                        color: themes.grayColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: themes.darkCyanBlue, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
