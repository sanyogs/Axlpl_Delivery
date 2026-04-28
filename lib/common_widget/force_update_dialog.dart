import 'dart:io';

import 'package:axlpl_delivery/const/app_update_config.dart';
import 'package:axlpl_delivery/utils/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

void showForceUpdateDialog({
  String? message,
  String? updateUrl,
}) {
  if (Get.isDialogOpen == true) {
    return;
  }

  final themes = Themes();
  final storeUrl = updateUrl?.trim().isNotEmpty == true
      ? updateUrl!.trim()
      : AppUpdateConfig.fallbackUpdateUrl;
  final updateMessage = message?.trim().isNotEmpty == true
      ? message!.trim()
      : AppUpdateConfig.fallbackUpdateMessage;

  Get.dialog(
    PopScope(
      canPop: false,
      child: Platform.isIOS
          ? CupertinoAlertDialog(
              title: const Text(AppUpdateConfig.updateTitle),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(updateMessage),
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => _openStore(storeUrl),
                  child: const Text('Update Now'),
                ),
              ],
            )
          : AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.system_update_alt,
                    color: themes.darkCyanBlue,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(AppUpdateConfig.updateTitle),
                  ),
                ],
              ),
              content: Text(updateMessage),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                ElevatedButton(
                  onPressed: () => _openStore(storeUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themes.darkCyanBlue,
                    foregroundColor: themes.whiteColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Update Now'),
                ),
              ],
            ),
    ),
    barrierDismissible: false,
  );
}

Future<void> _openStore(String storeUrl) async {
  final uri = Uri.parse(storeUrl);
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!launched) {
    Get.snackbar(
      AppUpdateConfig.updateTitle,
      'Open this link to update: $storeUrl',
      backgroundColor: Themes().darkCyanBlue,
      colorText: Themes().whiteColor,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
