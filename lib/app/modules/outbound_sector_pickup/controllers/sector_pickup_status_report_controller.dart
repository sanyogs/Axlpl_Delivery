import 'dart:io';

import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_status_report_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Admin **Sector Pickup Status Report** — paginated `pickupreport` API.
class SectorPickupStatusReportController extends GetxController {
  SectorPickupStatusReportController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isLoading = false.obs;
  final isExporting = false.obs;
  final reportPage = Rxn<SectorPickupStatusReportPage>();
  final currentPage = 1.obs;
  final loadError = ''.obs;

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final docketController = TextEditingController();
  final linehaulController = TextEditingController();

  final filterOriginBranchId = RxnString();
  final filterDestBranchId = RxnString();
  final filterStatus = RxnString();

  static const allBranchesLabel = 'All Branches';
  static const allStatusLabel = 'All Status';

  static const statusFilterOptions = <String>[
    allStatusLabel,
    'Sector Pickup Done',
    'Sector Pickup Pending',
  ];

  List<SectorPickupStatusReportRow> get rows =>
      reportPage.value?.rows ?? const [];

  int get totalPages {
    final pages = reportPage.value?.totalPages ?? 1;
    return pages < 1 ? 1 : pages;
  }

  int get totalCount => reportPage.value?.total ?? 0;

  int? get pickupDoneCount => reportPage.value?.pickupDone;

  int? get pickupPendingCount => reportPage.value?.pickupPending;

  String get rangeLabel {
    final page = reportPage.value;
    if (page == null || page.rows.isEmpty) return '';
    final start = (currentPage.value - 1) * page.limit + 1;
    final end = start + page.rows.length - 1;
    return 'Showing $start–$end of ${page.total}';
  }

  @override
  void onInit() {
    super.onInit();
    loadReport(page: 1);
  }

  @override
  void onClose() {
    startDateController.dispose();
    endDateController.dispose();
    docketController.dispose();
    linehaulController.dispose();
    super.onClose();
  }

  void prefillDates() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    startDateController.text = OutboundApiParams.formatReportDate(monthStart);
    endDateController.text = OutboundApiParams.formatReportDate(now);
  }

  void resetFilters() {
    startDateController.clear();
    endDateController.clear();
    docketController.clear();
    linehaulController.clear();
    filterOriginBranchId.value = null;
    filterDestBranchId.value = null;
    filterStatus.value = null;
    loadReport(page: 1);
  }

  String? _branchQueryValue(String? branchId) {
    final value = branchId?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? _statusQueryValue(String? label) {
    final value = label?.trim();
    if (value == null || value.isEmpty || value == allStatusLabel) {
      return null;
    }
    return value;
  }

  Future<void> loadReport({int? page}) async {
    final nextPage = page ?? currentPage.value;
    isLoading.value = true;
    loadError.value = '';
    try {
      final parsed = await _fetchReportPage(nextPage);

      if (parsed != null) {
        reportPage.value = parsed;
        currentPage.value = parsed.page.clamp(1, parsed.totalPages);
      } else if (loadError.value.isEmpty) {
        loadError.value = 'No report data returned.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> nextPage() async {
    if (currentPage.value >= totalPages) return;
    await loadReport(page: currentPage.value + 1);
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 1) return;
    await loadReport(page: currentPage.value - 1);
  }

  Future<SectorPickupStatusReportPage?> _fetchReportPage(
    int page, {
    bool recordLoadError = true,
  }) async {
    final r = await _repo.pickupReport(
      startDate: startDateController.text.trim(),
      endDate: endDateController.text.trim(),
      page: page,
      originBranch: _branchQueryValue(filterOriginBranchId.value),
      destinationBranch: _branchQueryValue(filterDestBranchId.value),
      docketNo: docketController.text.trim(),
      status: _statusQueryValue(filterStatus.value),
      linehaulNo: linehaulController.text.trim(),
    );

    SectorPickupStatusReportPage? parsed;
    r.when(
      success: (data) {
        parsed = SectorPickupStatusReportPage.fromDynamic(data);
      },
      error: (e) {
        if (recordLoadError) {
          loadError.value = e.message;
        }
      },
    );
    return parsed;
  }

  Future<void> exportCsv() async {
    isExporting.value = true;
    try {
      final r = await _repo.sectorPickupReportExport(
        startDate: startDateController.text.trim(),
        endDate: endDateController.text.trim(),
        originBranch: _branchQueryValue(filterOriginBranchId.value),
        destinationBranch: _branchQueryValue(filterDestBranchId.value),
        docketNo: docketController.text.trim(),
        status: _statusQueryValue(filterStatus.value),
        linehaulNo: linehaulController.text.trim(),
      );

      SectorPickupStatusReportPage? exportPage;
      r.when(
        success: (data) {
          exportPage = SectorPickupStatusReportPage.fromDynamic(data);
        },
        error: (e) {
          Get.snackbar(
            'Sector pickup',
            e.message,
            duration: const Duration(seconds: 4),
          );
        },
      );
      if (exportPage == null) return;

      final allRows = exportPage!.rows;
      if (allRows.isEmpty) {
        Get.snackbar('Sector pickup', 'No rows to export.');
        return;
      }

      final header = [
        'Shipment No',
        'Origin',
        'Destination',
        'Linehaul No',
        'Linehaul Date',
        'Pickup Status',
        'Pickup Date',
        'Current Status',
      ];
      final buffer = StringBuffer()
        ..writeln(header.map(_csvEscape).join(','));
      for (final row in allRows) {
        buffer.writeln(row.csvCells().map(_csvEscape).join(','));
      }

      Directory dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final fileName = 'sector_pickup_status_report_${allRows.length}_rows.csv';
      final exportDir = Directory('${dir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsString(buffer.toString(), flush: true);
      await _openExportedCsv(file.path);
    } finally {
      isExporting.value = false;
    }
  }

  static String _csvEscape(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  Future<void> _openExportedCsv(String path) async {
    const mimeTypes = <String>[
      'text/csv',
      'text/comma-separated-values',
      'application/vnd.ms-excel',
      'text/plain',
    ];

    for (final mime in mimeTypes) {
      final result = await OpenFile.open(
        path,
        type: mime,
      );
      if (result.type == ResultType.done) {
        Get.snackbar('Sector pickup', OutboundLabels.msgCsvExported);
        return;
      }
    }

    final fallback = await OpenFile.open(path);
    if (fallback.type == ResultType.done) {
      Get.snackbar('Sector pickup', OutboundLabels.msgCsvExported);
      return;
    }

    Get.snackbar(
      'Sector pickup',
      'CSV saved: $path',
      duration: const Duration(seconds: 4),
    );
  }
}
