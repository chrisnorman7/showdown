import 'package:flutter/material.dart';
import 'package:showdown/showdown.dart';

/// A widget to show the name of [player].
class PlayerName extends StatelessWidget {
  /// Create an instance.
  const PlayerName({required this.player, super.key});

  /// The player to show.
  final ShowdownPlayer player;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final int points;
    final events = player.events.where((final event) => event.points > 0);
    if (events.isEmpty) {
      points = 0;
    } else {
      points = events
          .map((final event) => event.points)
          .reduce((final value, final element) => value + element);
    }
    return Focus(child: Text('${player.name} ($points)'));
  }
}
