import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:axlpl_delivery/app/data/models/lat_long_model.dart';
import 'package:axlpl_delivery/utils/theme.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:logger/logger.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

Themes themes = Themes();
final player = AudioPlayer();

class Utils {
  Utils._privateConstructor();
  static final Utils instance = Utils._privateConstructor();
  static OverlayEntry? _topNotificationEntry;
  static Timer? _topNotificationTimer;

  Utils._internal();
  static final Utils _instance = Utils._internal();

  factory Utils() {
    return _instance;
  }

  // var logger = Logger(
  //   printer: PrettyPrinter(
  //     methodCount: 6, // Number of method calls to be displayed
  //     errorMethodCount: 10, // Number of method calls if stacktrace is provided
  //     lineLength: 500, // Width of the output
  //     colors: true, // Colorful log messages
  //     printEmojis: true, // Print an emoji for each log message
  //     // Should each log print contain a timestamp
  //   ),
  // );

  void logError(String message, [StackTrace? stackTrace]) {
    return;
    // Log the error message
    log("Error: $message");
    if (stackTrace != null) {
      log("StackTrace: $stackTrace");
    }
  }

  void logInfo(dynamic info) {
    // logger.i(info);
  }

  void log(
    dynamic info,
  ) {
    // logger.d(info);
  }

  Future<void> showTopNotification({
    String? title,
    required String message,
    bool isError = false,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    final normalizedTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : isError
            ? 'Failed'
            : 'Success';

    _insertTopNotification(
      title: normalizedTitle,
      message: normalizedMessage,
      isError: isError,
      attempt: 0,
    );
  }

  void _insertTopNotification({
    required String title,
    required String message,
    required bool isError,
    required int attempt,
  }) {
    final overlayState = _resolveOverlayState();
    if (overlayState == null) {
      if (attempt < 5) {
        Future.delayed(const Duration(milliseconds: 120), () {
          _insertTopNotification(
            title: title,
            message: message,
            isError: isError,
            attempt: attempt + 1,
          );
        });
      } else {
        Fluttertoast.cancel();
        Fluttertoast.showToast(
          msg: '$title\n$message',
          gravity: ToastGravity.TOP,
          backgroundColor: isError ? themes.redColor : themes.darkCyanBlue,
          textColor: themes.whiteColor,
          fontSize: 16.0,
          toastLength: Toast.LENGTH_LONG,
        );
      }
      return;
    }

    final backgroundColor = isError ? themes.redColor : themes.darkCyanBlue;
    _removeTopNotification();

    _topNotificationEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_topNotificationEntry!);
    _topNotificationTimer = Timer(
      const Duration(seconds: 3),
      _removeTopNotification,
    );
  }

  OverlayState? _resolveOverlayState() {
    final navigatorOverlay = Get.key.currentState?.overlay;
    if (navigatorOverlay != null) {
      return navigatorOverlay;
    }

    if (Get.overlayContext != null) {
      final overlay = Overlay.maybeOf(Get.overlayContext!, rootOverlay: true);
      if (overlay != null) {
        return overlay;
      }
    }

    if (Get.context != null) {
      final overlay = Overlay.maybeOf(Get.context!, rootOverlay: true);
      if (overlay != null) {
        return overlay;
      }
    }

    return null;
  }

  static void _removeTopNotification() {
    _topNotificationTimer?.cancel();
    _topNotificationTimer = null;
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;
  }

  String? validatePhone(String? value) {
    // Regex for phone number validation (example for US numbers)
    final RegExp phoneExp = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    } else if (!phoneExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? validateEmail(String? value) {
    // Regex for phone number validation (example for US numbers)
    final RegExp emailExp = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (value == null || value.isEmpty) {
      return 'Email ID is required';
    } else if (!emailExp.hasMatch(value)) {
      return 'Enter a valid @ Email ID';
    }
    return null;
  }

  String? validateFax(String? value) {
    // Accepts optional +, digits, spaces, dashes, parentheses, and dots, min 6 digits
    final RegExp faxExp = RegExp(r'^\+?[\d\s\-().]{6,}$');
    if (value == null || value.isEmpty) {
      return 'Fax number is required';
    } else if (!faxExp.hasMatch(value)) {
      return 'Enter a valid fax number';
    }
    return null;
  }

  String? validatePan(String? value) {
    // PAN: 5 uppercase letters, 4 digits, 1 uppercase letter
    final RegExp panExp = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    } else if (!panExp.hasMatch(value)) {
      return 'Enter a valid PAN number';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateText(String? value) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    return null;
  }

  String? validateGST(String? value) {
    // GSTIN format: 15 characters, first 2 digits are state code, next 10 are PAN, next 1 is entity code, next 1 is Z, last 1 is checksum
    final RegExp gstExp =
        RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (value == null || value.isEmpty) {
      return 'GST number is required';
    } else if (!gstExp.hasMatch(value)) {
      return 'Enter a valid GST number (15 characters)';
    }
    return null;
  }

  String? validateIndianZipcode(String? value) {
    // Indian PIN code: 6 digits, first digit 1-9
    final RegExp pinExp = RegExp(r'^[1-9][0-9]{5}$');
    if (value == null || value.isEmpty) {
      return 'PIN code is required';
    } else if (!pinExp.hasMatch(value)) {
      return 'Enter a valid 6-digit PIN code';
    }
    return null;
  }

  // Future<Position> determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //   }
  //   return await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  // }

  // Future<UserLocation> getUserLocation() async {
  //   final position = await determinePosition();
  //   final latitude = position.latitude;
  //   final longitude = position.longitude;

  //   List<Placemark> placemarks =
  //       await placemarkFromCoordinates(latitude, longitude);
  //   Placemark place = placemarks.first;

  //   final address =
  //       "${place.name}, ${place.street}, ${place.postalCode}, ${place.locality}, ${place.country}";

  //   return UserLocation(
  //     latitude: latitude,
  //     longitude: longitude,
  //     address: address,
  //   );
  // }

  Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // OR androidInfo.androidId (better)
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }

    return null;
  }

  Future<String?> scanAndPlaySound(BuildContext context) async {
    String? res = await SimpleBarcodeScanner.scanBarcode(
      scanType: ScanType.defaultMode,
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: '',
        centerTitle: false,
        enableBackButton: true,
        backButtonIcon: Icon(Icons.arrow_back_ios),
      ),
      isShowFlashIcon: true,
      cameraFace: CameraFace.back,
    );

    if (res != null && res.isNotEmpty && res != '-1') {
      await player.play(AssetSource('beep.mp3'));
      logInfo('Scanned: $res');
      return res; // <<<< return valid result here
    } else {
      log('Scan cancelled or invalid');
      return null; // <<<< or return null if invalid
    }
  }

  Future<void> urlLauncher(final urlLink) async {
    if (urlLink == null || urlLink.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid URL',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Clean and encode the URL
      String cleanUrl = urlLink.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final encodedUrl = Uri.encodeFull(cleanUrl);
      final url = Uri.parse(encodedUrl);

      print('Launching URL: $url'); // For debugging

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not open link',
          backgroundColor: Themes().redColor,
          colorText: Themes().whiteColor,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('URL Launch Error: $e'); // For debugging
      Get.snackbar(
        'Error',
        'Unable to open link',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> launchInvoiceUrl(String? invoiceLink) async {
    if (invoiceLink == null || invoiceLink.isEmpty) {
      Get.snackbar(
        'Error',
        'Invoice link not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Clean and prepare the URL
      String baseUrl = 'new.axlpl.com';
      String path = '/admin/customer/invoice_view/';
      String invoiceId = invoiceLink.split('/').last;

      // Construct the URL properly
      final uri = Uri.https(baseUrl, '$path$invoiceId');

      print('Launching Invoice URL: $uri'); // For debugging

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      print('Invoice URL Error: $e'); // For debugging
      Get.snackbar(
        'Error',
        'Unable to open invoice. Please try again later.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
