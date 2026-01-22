import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/siren_alert_payload.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SirenAlertScreen extends StatelessWidget {
  const SirenAlertScreen({
    super.key,
    required this.payload,
    this.onActionPressed,
  });

  final SirenAlertPayload payload;
  final void Function(SirenAlertAction action)? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = payload.data;

    final serviceName = _firstNonEmpty(
      data,
      const ['service', 'service_name', 'serviceName', 'app', 'app_name'],
    );
    final amount = _firstNonEmpty(
      data,
      const ['amount', 'fare', 'price', 'total', 'total_amount'],
    );
    final pickupEta = _firstNonEmpty(
      data,
      const ['pickup_eta', 'pickupEta', 'pickup_time', 'pickupTime'],
    );
    final pickupDistance = _firstNonEmpty(
      data,
      const ['pickup_distance', 'pickupDistance', 'distance_to_pickup'],
    );
    final pickupAddress = _firstNonEmpty(
      data,
      const [
        'pickup_address',
        'pickupAddress',
        'pickup',
        'from_address',
        'from',
        'source_address'
      ],
    );
    final dropoffEta = _firstNonEmpty(
      data,
      const ['dropoff_eta', 'dropoffEta', 'dropoff_time', 'dropoffTime'],
    );
    final dropoffDistance = _firstNonEmpty(
      data,
      const ['dropoff_distance', 'dropoffDistance', 'distance_to_dropoff'],
    );
    final dropoffAddress = _firstNonEmpty(
      data,
      const [
        'dropoff_address',
        'dropoffAddress',
        'dropoff',
        'to_address',
        'to',
        'destination_address'
      ],
    );

    final title = payload.title?.trim().isNotEmpty == true
        ? payload.title!.trim()
        : 'New Alert';
    final body = payload.body?.trim() ?? '';

    final shownKeys = <String>{
      'service',
      'service_name',
      'serviceName',
      'app',
      'app_name',
      'amount',
      'fare',
      'price',
      'total',
      'total_amount',
      'pickup_eta',
      'pickupEta',
      'pickup_time',
      'pickupTime',
      'pickup_distance',
      'pickupDistance',
      'distance_to_pickup',
      'pickup_address',
      'pickupAddress',
      'pickup',
      'from_address',
      'from',
      'source_address',
      'dropoff_eta',
      'dropoffEta',
      'dropoff_time',
      'dropoffTime',
      'dropoff_distance',
      'dropoffDistance',
      'distance_to_dropoff',
      'dropoff_address',
      'dropoffAddress',
      'dropoff',
      'to_address',
      'to',
      'destination_address',
    };

    final remainingEntries = data.entries
        .where((entry) => !shownKeys.contains(entry.key))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.25),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: theme.colorScheme.surface,
                  elevation: 6,
                  shape: const CircleBorder(),
	                  child: IconButton(
	                    icon: const Icon(Icons.close),
	                    onPressed: () {
	                      final navigator = Navigator.of(context);
	                      if (navigator.canPop()) {
	                        navigator.pop();
	                        return;
	                      }
	                      Get.offAllNamed(AppPages.INITIAL);
	                    },
	                  ),
	                ),
	              ),
	            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: _ServicePill(label: serviceName ?? 'AXLPL'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      amount ?? title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (pickupEta != null ||
                        pickupDistance != null ||
                        pickupAddress != null)
                      _TripLine(
                        marker: _TripMarker.circle,
                        primary: _joinNonEmpty([
                          if (pickupEta != null) pickupEta,
                          if (pickupDistance != null) pickupDistance,
                        ]),
                        secondary: pickupAddress,
                      ),
                    if (dropoffEta != null ||
                        dropoffDistance != null ||
                        dropoffAddress != null)
                      _TripLine(
                        marker: _TripMarker.square,
                        primary: _joinNonEmpty([
                          if (dropoffEta != null) dropoffEta,
                          if (dropoffDistance != null) dropoffDistance,
                        ]),
                        secondary: dropoffAddress,
                      ),
                    if (payload.actions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ActionButtons(
                        actions: payload.actions,
                        onPressed: onActionPressed,
                      ),
                    ],
                    if (remainingEntries.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: remainingEntries.length,
                          separatorBuilder: (_, __) => const Divider(height: 18),
                          itemBuilder: (context, index) {
                            final entry = remainingEntries[index];
                            return _KeyValueRow(
                              label: entry.key,
                              value: entry.value?.toString() ?? '',
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.actions,
    this.onPressed,
  });

  final List<SirenAlertAction> actions;
  final void Function(SirenAlertAction action)? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (actions.length == 1) {
      final action = actions.first;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed == null ? null : () => onPressed!(action),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(action.label),
        ),
      );
    }

    if (actions.length == 2) {
      final primary = actions[0];
      final secondary = actions[1];
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onPressed == null ? null : () => onPressed!(primary),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(primary.label),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onPressed == null ? null : () => onPressed!(secondary),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(secondary.label),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (var index = 0; index < actions.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: index == actions.length - 1 ? 0 : 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed == null
                    ? null
                    : () => onPressed!(actions[index]),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  actions[index].label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ServicePill extends StatelessWidget {
  const _ServicePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.onSurface.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.75),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TripMarker { circle, square }

class _TripLine extends StatelessWidget {
  const _TripLine({
    required this.marker,
    this.primary,
    this.secondary,
  });

  final _TripMarker marker;
  final String? primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markerWidget = switch (marker) {
      _TripMarker.circle => const Icon(Icons.circle, size: 10),
      _TripMarker.square => const Icon(Icons.square, size: 10),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: markerWidget,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primary != null && primary!.trim().isNotEmpty)
                  Text(
                    primary!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (secondary != null && secondary!.trim().isNotEmpty)
                  Text(
                    secondary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String? _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key]?.toString();
    if (value == null) continue;
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _joinNonEmpty(List<String?> parts) {
  final cleaned = parts
      .where((value) => value != null && value.trim().isNotEmpty)
      .map((value) => value!.trim())
      .toList();
  if (cleaned.isEmpty) return null;
  return cleaned.join(' • ');
}
