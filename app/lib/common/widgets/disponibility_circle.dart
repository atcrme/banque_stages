import 'package:crcrme_banque_stages/common/widgets/numbered_tablet.dart';
import 'package:flutter/material.dart';

class DisponibilityCircle extends StatelessWidget {
  const DisponibilityCircle({
    super.key,
    required this.positionsOffered,
    required this.positionsOccupied,
    this.enabled = true,
  });

  final int positionsOffered;
  final int positionsOccupied;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    int remainning = positionsOffered - positionsOccupied;
    return Tooltip(
      message: 'Nombre de places disponibles pour ce métier',
      child: NumberedTablet(
        number: remainning,
        enabled: enabled,
        color: enabled
            ? (remainning > 0 ? Colors.green[800] : Colors.red[800])
            : Colors.grey[800],
      ),
    );
  }
}
