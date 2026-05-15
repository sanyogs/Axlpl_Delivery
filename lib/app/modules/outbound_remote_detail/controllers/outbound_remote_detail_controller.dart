import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailController extends GetxController {
  OutboundRemoteDetailController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isLoading = true.obs;
  final detailText = ''.obs;
  final summaryLines = <String>[].obs;
  final title = ''.obs;

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
        return 'Bag $_id';
      case 'manifest':
        return 'Manifest $_id';
      case 'linehaul':
        return 'Linehaul $_id';
      default:
        return 'Outbound detail';
    }
  }

  Future<void> _load() async {
    if (_id.isEmpty || _kind.isEmpty) {
      summaryLines.clear();
      detailText.value = 'Missing kind or id in route arguments.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    summaryLines.clear();
    try {
      dynamic rawForPretty;
      switch (_kind) {
        case 'bag':
          final data = await _repo.bagDetails(_id);
          summaryLines.assignAll(data?.summaryLines ?? []);
          rawForPretty = data?.rawForDisplay;
          break;
        case 'manifest':
          final data = await _repo.manifestDetails(_id);
          summaryLines.assignAll(data?.summaryLines ?? []);
          rawForPretty = data?.rawForDisplay;
          break;
        case 'linehaul':
          final data = await _repo.linehaulDetails(_id);
          summaryLines.assignAll(data?.summaryLines ?? []);
          rawForPretty = data?.rawForDisplay;
          break;
        default:
          detailText.value = 'Unknown kind: $_kind';
          isLoading.value = false;
          return;
      }
      if (rawForPretty == null) {
        detailText.value =
            _repo.lastMessage.isNotEmpty ? _repo.lastMessage : 'No data.';
      } else {
        detailText.value = OutboundDataParse.pretty(rawForPretty);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => _load();
}
