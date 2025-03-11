import 'package:flutter/material.dart';
import 'package:showdown/showdown.dart';

/// The goal button
class GoalButton extends StatelessWidget {
  /// Create an instance.
  const GoalButton({required this.addEvent, super.key});

  /// The function to call to add the event.
  final ValueChanged<ShowdownEvent> addEvent;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => IconButton(
    onPressed: () => addEvent(ShowdownEvent(points: 2, description: 'Goal')),
    icon: const Icon(Icons.sports_soccer, semanticLabel: 'Add goal'),
    tooltip: 'Add goal',
  );
}
