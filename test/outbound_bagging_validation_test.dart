import 'package:axlpl_delivery/app/modules/outbound_bagging/outbound_bagging_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bagging validators are non-blocking', () {
    expect(OutboundBaggingValidation.validateMetalSealNo(''), isNull);
    expect(OutboundBaggingValidation.validateMetalSealNo('BAG123'), isNull);
    expect(
      OutboundBaggingValidation.validateDepots(
        originBranchId: null,
        destinationBranchId: null,
      ),
      isNull,
    );
    expect(
      OutboundBaggingValidation.validateBagCode('', required: true),
      isNull,
    );
    expect(
      OutboundBaggingValidation.validateShipmentDocket(''),
      isNull,
    );
    expect(
      OutboundBaggingValidation.validateBaggingReportRequest(
        bagCode: '',
      ),
      isNull,
    );
  });
}
