import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outboundFirstSuccessWhere skips empty payloads', () async {
    var calls = 0;
    final r = await outboundFirstSuccessWhere(
      [
        () async {
          calls++;
          return APIResponse.success({'id': ''});
        },
        () async {
          calls++;
          return APIResponse.success({'manifest_no': 'AHM002'});
        },
      ],
      (data) =>
          data is Map && (data['manifest_no']?.toString().trim().isNotEmpty ?? false),
    );

    expect(calls, 2);
    r.when(
      success: (data) => expect((data as Map)['manifest_no'], 'AHM002'),
      error: (_) => fail('expected success'),
    );
  });

  test('outboundFirstSuccess returns last response when all fail', () async {
    final r = await outboundFirstSuccess([
      () async => APIResponse.error(AppException.errorWithMessage('first')),
      () async => APIResponse.error(AppException.errorWithMessage('last')),
    ]);

    r.when(
      success: (_) => fail('expected error'),
      error: (e) => expect(e.message, 'last'),
    );
  });

  test('manifest fetch retry skips id-only manifest payloads', () async {
    var calls = 0;
    final r = await outboundFirstSuccessWhere(
      [
        () async {
          calls++;
          return APIResponse.success({'id': '381'});
        },
        () async {
          calls++;
          return APIResponse.success({
            'id': '381',
            'manifest_no': 'MUM208',
            'bags': [
              {'id': '379', 'bag_code': 'BAG20260608224439'},
            ],
          });
        },
      ],
      (data) => ManifestDetail.fromDynamic(data).hasContent,
    );

    expect(calls, 2);
    r.when(
      success: (data) {
        final detail = ManifestDetail.fromDynamic(data);
        expect(detail.manifestNo, 'MUM208');
      },
      error: (_) => fail('expected success'),
    );
  });
}
