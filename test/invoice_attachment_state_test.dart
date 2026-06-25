import 'package:axlpl_delivery/app/modules/pickdup_delivery_details/invoice_attachment_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows up to 3 attachments total', () {
    expect(InvoiceAttachmentState.maxInvoiceAttachments, 3);
    expect(InvoiceAttachmentState.canAddMore(0), isTrue);
    expect(InvoiceAttachmentState.canAddMore(2), isTrue);
    expect(InvoiceAttachmentState.canAddMore(3), isFalse);
    expect(InvoiceAttachmentState.remainingSlots(2), 1);
    expect(InvoiceAttachmentState.remainingSlots(3), 0);
  });

  test('counts uploaded invoice files from string and list', () {
    expect(InvoiceAttachmentState.uploadedCountFromInvoiceFile(null), 0);
    expect(InvoiceAttachmentState.uploadedCountFromInvoiceFile(''), 0);
    expect(InvoiceAttachmentState.uploadedCountFromInvoiceFile('a.jpg'), 1);
    expect(
      InvoiceAttachmentState.uploadedCountFromInvoiceFile('a.jpg,b.jpg'),
      2,
    );
    expect(
      InvoiceAttachmentState.uploadedCountFromInvoiceFile(
        ['a.jpg', 'b.jpg', 'c.jpg'],
      ),
      3,
    );
  });

  test('remaining slots include uploaded and pending attachments', () {
    expect(
      InvoiceAttachmentState.remainingSlots(
        InvoiceAttachmentState.totalCount(
          uploadedCount: 1,
          pendingCount: 1,
        ),
      ),
      1,
    );
    expect(
      InvoiceAttachmentState.remainingSlots(
        InvoiceAttachmentState.totalCount(
          uploadedCount: 2,
          pendingCount: 1,
        ),
      ),
      0,
    );
  });

  test('removeAt keeps list unchanged for invalid index', () {
    final out = InvoiceAttachmentState.removeAt(const [], 0);
    expect(out, isEmpty);
  });
}
