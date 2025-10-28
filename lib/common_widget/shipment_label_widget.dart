import 'package:axlpl_delivery/common_widget/common_textfiled.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ShipmentLabelDialog extends StatelessWidget {
  final VoidCallback onPrint;
  final TextEditingController labelCountController;
  final _formKey = GlobalKey<FormState>();

  ShipmentLabelDialog({
    Key? key,
    required this.onPrint,
    required this.labelCountController,
  }) : super(key: key) {
    if (labelCountController.text.isEmpty) {
      labelCountController.text = '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(16),
                child: Icon(Icons.print, color: Color(0xFFFF6600), size: 40),
              ),
              SizedBox(height: 16),
              Text(
                'Print Shipment Labels',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'shipping labels for your shipment',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Number of Labels',
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 16.sp),
                ),
              ),
              SizedBox(height: 8.h),
              Form(
                key: _formKey,
                child: CommonTextfiled(
                  controller: labelCountController,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter number of labels';
                    }
                    final intValue = int.tryParse(val);
                    if (intValue == null || intValue < 1 || intValue > 10) {
                      return 'enter number between 1 and 10';
                    }
                    return null;
                  },
                  hintTxt: 'Enter number of labels',
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  // Icon(Icons.info_outline,
                  //     color: themes.darkCyanBlue, size: 18),
                  // SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Enter a number between 1 and 10',
                      style: TextStyle(
                          fontSize: 13.sp, color: themes.darkCyanBlue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themes.orangeColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                      ),
                      onPressed: () {
                        // Validate the entered label count (disallow 0)
                        if (_formKey.currentState?.validate() ?? false) {
                          onPrint();
                        } else {
                          // Brief feedback when validation fails
                          Get.snackbar(
                            'Invalid',
                            'Please enter a valid label count',
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      icon: Icon(
                        Icons.print,
                        size: 20,
                        color: themes.whiteColor,
                      ),
                      label: const Text('Print Labels'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
