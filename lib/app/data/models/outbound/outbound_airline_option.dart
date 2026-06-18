import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Airline row from `getairlines`.
class OutboundAirlineOption {
  const OutboundAirlineOption({
    required this.id,
    required this.name,
    this.code,
    this.prefix,
  });

  final String id;
  final String name;
  final String? code;
  final String? prefix;

  String get label {
    final c = code?.trim();
    if (c != null && c.isNotEmpty) return '$name ($c)';
    return name;
  }

  factory OutboundAirlineOption.fromJson(Map<String, dynamic> json) {
    final id = OutboundDataParse.firstNonEmptyString(json, const [
          'id',
          'airline_id',
          'airlineId',
          'value',
        ]) ??
        '';
    final name = OutboundDataParse.firstNonEmptyString(json, const [
          'airline_name',
          'airline',
          'name',
          'label',
          'title',
          'text',
        ]) ??
        id;
    return OutboundAirlineOption(
      id: id,
      name: name,
      code: OutboundDataParse.firstNonEmptyString(json, const [
        'code',
        'airline_code',
      ]),
      prefix: OutboundDataParse.optionalString(json, 'prefix'),
    );
  }

  static List<OutboundAirlineOption> listFromDynamic(dynamic data) {
    final rows = <OutboundAirlineOption>[];
    for (final raw in OutboundDataParse.asList(data)) {
      if (raw is String || raw is num) {
        final value = raw.toString().trim();
        if (value.isNotEmpty) {
          rows.add(OutboundAirlineOption(id: value, name: value));
        }
        continue;
      }
      final map = OutboundDataParse.asStringKeyedMap(raw);
      if (map != null) rows.add(OutboundAirlineOption.fromJson(map));
    }

    final seen = <String>{};
    final out = <OutboundAirlineOption>[];
    for (final row in rows) {
      if (row.id.isEmpty || row.name.isEmpty) continue;
      if (!seen.add(row.id)) continue;
      out.add(row);
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  OutboundAirlineOption copyWith({
    String? id,
    String? name,
    String? code,
    String? prefix,
  }) {
    return OutboundAirlineOption(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      prefix: prefix ?? this.prefix,
    );
  }
}
