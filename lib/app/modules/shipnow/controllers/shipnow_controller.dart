import 'dart:isolate';
import 'dart:ui';
import 'dart:io';
import 'package:axlpl_delivery/app/data/models/shipnow_data_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/shipnow_repo.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:axlpl_delivery/utils/theme.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';

class ShipnowController extends GetxController {
  // Status filter options
  final RxString selectedStatusFilter = ''.obs;
  final List<String> statusFilters = [
    '', // All
    'Out for delivery',
    'Waiting for pickup',
    'Picked up',
    'Approved',
    'Pending',
    'Cancelled',
    // Add more statuses as needed
  ];
  final themes = Themes();
  final isDownloadingLabel = false.obs;

  // Repository
  final shipNowRepo = ShipnowRepo();

  // Data storage
  final allShipmentData = <ShipmentDatum>[].obs;
  final filteredShipmentData = <ShipmentDatum>[].obs;

  // Loading states
  final isLoadingShipNow = false.obs;
  final isLoadingMore = false.obs;

  // Controllers
  final shipmentIDController = TextEditingController();
  final TextEditingController shipmentLabelCountController =
  TextEditingController();

  final Map<String, TextEditingController> shipmentLableControllers = {};

  // Pagination variables
  int currentPage = 0;
  bool hasMoreData = true;
  static const int pageSize = 10;

  TextEditingController getLableController(String shipmentId) =>
      shipmentLableControllers.putIfAbsent(
          shipmentId, () => TextEditingController());

  Future<void> fetchShipmentData(String nextID,
      {bool isRefresh = false, final shipmentStatus}) async {
    try {
      // Start loading state
      if (isRefresh) {
        isLoadingShipNow(true);
        currentPage = 0;
        hasMoreData = true;
      } else {
        isLoadingMore(true);
      }

      // Fetch data from repository
      final data = await shipNowRepo.customerListRepo(
        nextID,
        shipmentStatus,
        shipmentIDController.text, // Search query
        '', '', '', '', '', '', '', '',
      );

      final newItems = data ?? [];

      // Update data based on refresh or pagination
      if (isRefresh) {
        allShipmentData.value = newItems;
      } else {
        allShipmentData.addAll(newItems);
      }

      // Check if we have more data to load
      hasMoreData = newItems.length >= pageSize;
    } catch (e) {
      // Handle error and clear data if refreshing
      if (isRefresh) {
        allShipmentData.clear();
        filteredShipmentData.clear();
      }
      Utils().logError('Shipment fetch failed $e');
    } finally {
      // Reset loading state
      if (isRefresh) {
        isLoadingShipNow(false);
      } else {
        isLoadingMore(false);
      }
    }
  }

  // Isolate for download progress
  final ReceivePort _port = ReceivePort();

  @override
  void onInit() {
    super.onInit();
    // Initial data load
    fetchShipmentData('0', isRefresh: true);

    // Only setup flutter_downloader for Android
    if (Platform.isAndroid) {
      IsolateNameServer.registerPortWithName(
          _port.sendPort, 'downloader_send_port');
      _port.listen((dynamic data) {
        DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);

        if (status == DownloadTaskStatus.complete) {
          _showSuccessToast(
              "Label downloaded successfully! Please check your downloads");
        } else if (status == DownloadTaskStatus.failed) {
          _showErrorToast("Label download failed");
        }
      });

      FlutterDownloader.registerCallback(downloadCallback);
    }

    // Listen to shipment ID changes for filtering
    shipmentIDController.addListener(() {
      fetchShipmentData('0', isRefresh: true, shipmentStatus: selectedStatusFilter.value);
    });
  }

  @override
  void onClose() {
    // Cleanup flutter_downloader for Android
    if (Platform.isAndroid) {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
    }
    super.onClose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
    IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  // Download shipment label
  Future<void> downloadShipmentLable(String url, String fileName) async {
    isDownloadingLabel.value = true;
    try {
      if (Platform.isIOS) {
        // iOS-specific download using direct file write
        await _downloadFileForIOS(url, fileName);
      } else {
        // Android download using flutter_downloader
        await _downloadFileForAndroid(url, fileName);
      }
    } catch (e) {
      print('Download error: $e');
      _showErrorToast("Failed to start download: ${e.toString()}");
    } finally {
      isDownloadingLabel.value = false;
    }
  }

  // iOS-specific file download
  Future<void> _downloadFileForIOS(String url, String fileName) async {
    try {
      // Get the documents directory for iOS
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName-label.pdf';

      // Use Dio for downloading
      final dio = Dio();

      _showSuccessToast("Label download started...");

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Download progress: $progress%');
          }
        },
      );

      _showSuccessToast("Label downloaded successfully!");

      // Show option to open the file
      Get.dialog(
        Platform.isIOS
            ? CupertinoAlertDialog(
          title: Text('Download Complete'),
          content: Text(
              'Label downloaded successfully. Would you like to open it?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Get.back();
                await OpenFile.open(filePath);
              },
              child: Text('Open'),
            ),
          ],
        )
            : AlertDialog(
          title: Text('Download Complete'),
          content: Text(
              'Label downloaded successfully. Would you like to open it?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                await OpenFile.open(filePath);
              },
              child: Text('Open'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('iOS download error: $e');
      _showErrorToast("Failed to start download: ${e.toString()}");
    }
  }

  // Android-specific file download
  Future<void> _downloadFileForAndroid(String url, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final savedDir = directory?.path ?? '/storage/emulated/0/Download';

      await FlutterDownloader.enqueue(
        url: url,
        headers: {},
        savedDir: savedDir,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
        fileName: '$fileName-label.pdf',
      );

      _showSuccessToast("Label download started");
    } catch (e) {
      print('Android download error: $e');
      throw Exception('Android download failed: $e');
    }
  }

  // Show success toast
  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: themes.darkCyanBlue,
      textColor: themes.whiteColor,
      fontSize: 16.0,
    );
  }

  // Show error toast
  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: themes.redColor,
      textColor: themes.whiteColor,
      fontSize: 16.0,
    );
  }

  // Load more data when paginating
  Future<void> loadMoreData() async {
    if (!hasMoreData || isLoadingMore.value) return;

    currentPage++;
    await fetchShipmentData(currentPage.toString(), isRefresh: false);
  }

  // Refresh data
  Future<void> refreshData() async {
    await fetchShipmentData('0',
        isRefresh: true, shipmentStatus: selectedStatusFilter.value);
  }

  // Filter data based on search query
  void filterShipmentData(String query) {
    filteredShipmentData.value = allShipmentData.where((data) {
      final matchesQuery = query.isEmpty ||
          (data.shipmentId?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (data.origin?.toLowerCase().contains(query.toLowerCase()) ?? false);

      final matchesStatus = selectedStatusFilter.value.isEmpty ||
          (data.shipmentStatus?.toLowerCase() ==
              selectedStatusFilter.value.toLowerCase());

      return matchesQuery && matchesStatus;
    }).toList();
  }

  // Call this when user selects a status filter from the filter list button
  void setStatusFilter(String status) {
    selectedStatusFilter.value = status;
    fetchShipmentData("0", isRefresh: true, shipmentStatus: status);
  }
}
