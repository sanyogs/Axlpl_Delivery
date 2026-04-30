import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ContractCard extends StatelessWidget {
  final String title;
  final used;
  final total;
  final String? endDate;
  final onTap;

  const ContractCard({
    super.key,
    required this.title,
    required this.used,
    required this.total,
    this.endDate,
    this.onTap,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(raw);
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      return '$day/$month/${parsed.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usedAmount = used is num ? used.toDouble() : 0.0;
    final totalAmount = total is num ? total.toDouble() : 0.0;
    final percent = totalAmount <= 0 ? 0.0 : usedAmount / totalAmount;
    double displayedPercent = percent.clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: themes.blueGray,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contract",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    // Text(
                    //   title,
                    //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    // ),
                    const SizedBox(height: 8),
                    Text(
                      "Used / Total",
                      style: TextStyle(
                        color: themes.grayColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${usedAmount.toStringAsFixed(2)} / ₹${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "End Date",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(endDate),
                      style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    )
                  ],
                ),
              ),

              // Circular Percent
              CircularPercentIndicator(
                radius: 45.0,
                lineWidth: 8.0,
                percent: displayedPercent,
                center: Text(
                  "${(displayedPercent * 100).toStringAsFixed(0)}%",
                  style: themes.fontSize14_500,
                ),
                progressColor: Colors.orange,
                backgroundColor: Colors.grey.shade300,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
