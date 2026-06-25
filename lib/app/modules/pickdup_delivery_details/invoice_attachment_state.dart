import 'dart:convert';
import 'dart:io';

/// Pending invoice attachments for a shipment (max [maxInvoiceAttachments] total).
class InvoiceAttachmentState {
  InvoiceAttachmentState._();

  static const int maxInvoiceAttachments = 3;

  static int remainingSlots(int currentCount) {
    final remaining = maxInvoiceAttachments - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  static bool canAddMore(int currentCount) =>
      currentCount < maxInvoiceAttachments;

  static int uploadedCountFromInvoiceFile(dynamic invoiceFile) {
    if (invoiceFile == null) return 0;
    if (invoiceFile is List) {
      return invoiceFile
          .where((item) => item?.toString().trim().isNotEmpty == true)
          .length;
    }
    final raw = invoiceFile.toString().trim();
    if (raw.isEmpty) return 0;
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .where((item) => item?.toString().trim().isNotEmpty == true)
              .length;
        }
      } catch (_) {}
    }
    final parts = raw
        .split(RegExp(r'[,|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 1 : parts.length;
  }

  static List<String> uploadedInvoiceUrls({
    required String? invoicePath,
    required dynamic invoiceFile,
  }) {
    final base = (invoicePath ?? '').trim();
    final urls = <String>[];

    void addPart(String value) {
      final part = value.trim();
      if (part.isEmpty) return;
      if (part.startsWith('http://') || part.startsWith('https://')) {
        urls.add(part);
        return;
      }
      urls.add('$base$part');
    }

    if (invoiceFile == null) return urls;
    if (invoiceFile is List) {
      for (final item in invoiceFile) {
        addPart(item?.toString() ?? '');
      }
      return urls;
    }

    final raw = invoiceFile.toString().trim();
    if (raw.isEmpty) return urls;
    if (raw.startsWith('[')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            addPart(item.toString());
          }
          return urls;
        }
      } catch (_) {}
    }

    final parts = raw
        .split(RegExp(r'[,|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      addPart(raw);
    } else {
      for (final part in parts) {
        addPart(part);
      }
    }
    return urls;
  }

  static int totalCount({
    required int uploadedCount,
    required int pendingCount,
  }) =>
      uploadedCount + pendingCount;

  static List<File> appendFiles(List<File> current, List<File> incoming) {
    if (incoming.isEmpty) return List<File>.from(current);
    final out = List<File>.from(current);
    final slots = remainingSlots(out.length);
    if (slots <= 0) return out;
    out.addAll(incoming.take(slots));
    return out;
  }

  static List<File> removeAt(List<File> current, int index) {
    if (index < 0 || index >= current.length) return List<File>.from(current);
    final out = List<File>.from(current);
    out.removeAt(index);
    return out;
  }
}
