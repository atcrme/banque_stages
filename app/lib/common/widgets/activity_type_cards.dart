import 'package:common/models/enterprises/enterprise.dart';
import 'package:flutter/material.dart';

class ActivityTypeCards extends StatelessWidget {
  const ActivityTypeCards({
    super.key,
    required this.activityTypes,
    this.onDeleted,
  });

  final Set<ActivityTypes> activityTypes;
  final void Function(ActivityTypes activityType)? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activityTypes
          .map(
            (activityType) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                  visualDensity: VisualDensity.compact,
                  deleteIcon: const Icon(Icons.delete, color: Colors.black),
                  deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                  label: Text(
                    activityType.toString(),
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.normal),
                  ),
                  backgroundColor: const Color(0xFFB8D8E6),
                  side: BorderSide.none,
                  onDeleted: onDeleted != null
                      ? () => onDeleted!(activityType)
                      : null),
            ),
          )
          .toList(),
    );
  }
}
