import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_remote_detail/controllers/outbound_remote_detail_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailView extends GetView<OutboundRemoteDetailController> {
  const OutboundRemoteDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isLoading.value;
      return OutboundScreen(
        title: controller.title.value,
        busy: busy,
        onRefresh: controller.reload,
        children: [
          if (controller.errorMessage.value.isNotEmpty)
            _ErrorBanner(message: controller.errorMessage.value),
          if (!busy && controller.bagDetail.value != null)
            OutboundBagDetailBody(detail: controller.bagDetail.value!),
          if (!busy && controller.manifestDetail.value != null)
            OutboundManifestDetailBody(
              detail: controller.manifestDetail.value!,
            ),
          if (!busy && controller.linehaulDetail.value != null)
            OutboundLinehaulDetailBody(
              detail: controller.linehaulDetail.value!,
            ),
          if (!busy &&
              controller.errorMessage.value.isEmpty &&
              controller.bagDetail.value == null &&
              controller.manifestDetail.value == null &&
              controller.linehaulDetail.value == null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No detail data.',
                  style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: themes.redColor.withValues(alpha: 0.08),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Text(
          message,
          style: themes.fontSize14_400.copyWith(color: themes.redColor),
        ),
      ),
    );
  }
}
