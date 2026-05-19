import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailController extends GetxController {
  OutboundRemoteDetailController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final title = ''.obs;

  final bagDetail = Rxn<BagDetail>();
  final manifestDetail = Rxn<ManifestDetail>();
  final linehaulDetail = Rxn<LinehaulDetail>();

  late String _kind;
  late String _id;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _kind = args['kind']?.toString() ?? '';
      _id = args['id']?.toString() ?? '';
    } else {
      _kind = '';
      _id = '';
    }
    title.value = _titleForKind(_kind);
    _load();
  }

  String _titleForKind(String k) {
    switch (k) {
      case 'bag':
        return 'Bag detail';
      case 'manifest':
        return 'Manifest detail';
      case 'linehaul':
        return 'Linehaul detail';
      default:
        return 'Detail';
    }
  }

  Future<void> _load() async {
    bagDetail.value = null;
    manifestDetail.value = null;
    linehaulDetail.value = null;
    errorMessage.value = '';

    if (_id.isEmpty || _kind.isEmpty) {
      errorMessage.value = 'Missing kind or id in route arguments.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      switch (_kind) {
        case 'bag':
          final data = await _repo.bagDetails(_id);
          if (data == null) {
            errorMessage.value = _repo.lastMessage.isNotEmpty
                ? _repo.lastMessage
                : 'Could not load bag details.';
          } else {
            bagDetail.value = data;
            if (data.bagCode != null && data.bagCode!.isNotEmpty) {
              title.value = 'Bag ${data.bagCode}';
            }
          }
          break;
        case 'manifest':
          final data = await _repo.manifestDetails(_id);
          if (data == null) {
            errorMessage.value = _repo.lastMessage.isNotEmpty
                ? _repo.lastMessage
                : 'Could not load manifest details.';
          } else {
            manifestDetail.value = data;
            final ref = data.manifestNo ?? data.id;
            if (ref != null && ref.isNotEmpty) {
              title.value = 'Manifest $ref';
            }
          }
          break;
        case 'linehaul':
          final data = await _repo.linehaulDetails(_id);
          if (data == null) {
            errorMessage.value = _repo.lastMessage.isNotEmpty
                ? _repo.lastMessage
                : 'Could not load linehaul details.';
          } else {
            linehaulDetail.value = data;
            final ref = data.tripNo ?? data.linehaulId;
            if (ref != null && ref.isNotEmpty) {
              title.value = 'Linehaul $ref';
            }
          }
          break;
        default:
          errorMessage.value = 'Unknown detail type: $_kind';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => _load();
}
