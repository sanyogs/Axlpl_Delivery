import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assignLinehaulBody prefers manifest_codes for AHM002', () {
    final body = OutboundApiParams.assignLinehaulBody(
      manifestCodesCsv: 'AHM002',
      vehicleNo: 'UP78HJKD',
      driverName: 'surface',
      userId: '148',
    );
    expect(body['manifest_codes'], 'AHM002');
    expect(body.containsKey('manifest_ids'), isFalse);
  });

  test('manifestDetailQueries tries manifest_code before manifest_id', () {
    final queries = OutboundApiParams.manifestDetailQueries('MUM208');
    expect(queries.first.containsKey('manifest_code'), isTrue);
    expect(queries.first['manifest_code'], 'MUM208');
    expect(queries.any((q) => q.containsKey('manifest_id')), isFalse);
    expect(queries.any((q) => q.containsKey('manifest_no')), isFalse);
  });

  test('linehaulDetailQueries prefers trip_no for LH refs', () {
    final queries = OutboundApiParams.linehaulDetailQueries('LH1781776125');
    expect(queries.first['trip_no'], 'LH1781776125');
  });

  test('assignLinehaulManifestFields uses manifest_ids for numeric refs', () {
    final body = OutboundApiParams.assignLinehaulManifestFields('381');
    expect(body['manifest_ids'], '381');
    expect(body.containsKey('manifest_codes'), isFalse);
  });
}
