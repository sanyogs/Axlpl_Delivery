import 'dart:io';

class AppUpdateConfig {
  static const String minimumSupportedVersion = '22.2.0+52';
  static const String updateTitle = 'Update required';
  static const String updateMessage =
      'A newer version of AXLPL Delivery is required to continue.';
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.axlpl.delivery';
  static const String iosStoreUrl =
      'https://apps.apple.com/us/search?term=AXLPL%20Delivery';

  static String get storeUrl => Platform.isIOS ? iosStoreUrl : androidStoreUrl;

  static bool requiresUpdate(String currentVersion) {
    return compareVersions(currentVersion, minimumSupportedVersion) < 0;
  }

  static int compareVersions(String left, String right) {
    final leftVersion = _parseVersion(left);
    final rightVersion = _parseVersion(right);

    for (var index = 0; index < 3; index++) {
      final comparison = leftVersion.semantic[index].compareTo(
        rightVersion.semantic[index],
      );
      if (comparison != 0) {
        return comparison;
      }
    }

    return leftVersion.build.compareTo(rightVersion.build);
  }

  static _ParsedVersion _parseVersion(String value) {
    final normalizedValue = value.replaceAll('-', '+');
    final parts = normalizedValue.split('+');
    final semanticParts = parts.first.split('.');

    int readPart(int index) {
      if (index >= semanticParts.length) {
        return 0;
      }
      return int.tryParse(semanticParts[index]) ?? 0;
    }

    return _ParsedVersion(
      semantic: [
        readPart(0),
        readPart(1),
        readPart(2),
      ],
      build: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }
}

class _ParsedVersion {
  const _ParsedVersion({
    required this.semantic,
    required this.build,
  });

  final List<int> semantic;
  final int build;
}
