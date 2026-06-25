import 'dart:io';

/// Pending invoice attachments for a shipment (max [maxInvoiceAttachments]).
class InvoiceAttachmentState {
  InvoiceAttachmentState._();

  static const int maxInvoiceAttachments = 3;

  static int remainingSlots(int currentCount) {
    final remaining = maxInvoiceAttachments - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  static bool canAddMore(int currentCount) =>
      currentCount < maxInvoiceAttachments;

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
