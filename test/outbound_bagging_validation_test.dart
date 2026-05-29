import 'package:axlpl_delivery/app/modules/outbound_bagging/outbound_bagging_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('metal seal rejects BAG prefix codes', () {
    expect(
      OutboundBaggingValidation.validateMetalSealNo('BAG20260518152744831'),
      isNotNull,
    );
    expect(
      OutboundBaggingValidation.validateMetalSealNo('VAL15052026MUM'),
      isNull,
    );
  });

  test('bagging report requires dates or bag code', () {
    expect(
      OutboundBaggingValidation.validateBaggingReportRequest(
        bagCode: '',
        startDate: '',
        endDate: '',
      ),
      isNotNull,
    );
    expect(
      OutboundBaggingValidation.validateBaggingReportRequest(
        bagCode: 'BAG20260518152744831',
        startDate: '',
        endDate: '',
      ),
      isNull,
    );
    expect(
      OutboundBaggingValidation.validateBaggingReportRequest(
        bagCode: '',
        startDate: '2026-01-01',
        endDate: '2026-05-18',
      ),
      isNull,
    );
  });

  test('depots both required', () {
    expect(
      OutboundBaggingValidation.validateDepots(
        originBranchId: '75',
        destinationBranchId: null,
      ),
      isNotNull,
    );
    expect(
      OutboundBaggingValidation.validateDepots(
        originBranchId: '75',
        destinationBranchId: '29',
      ),
      isNull,
    );
  });
}
