import 'package:flutter/material.dart';
import 'package:showdown/showdown.dart';

/// A [ListTile] which shows an [event].
class ShowdownEventListTile extends StatelessWidget {
  /// Create an instance.
  const ShowdownEventListTile({required this.event, this.player, super.key});

  /// The event to show.
  final ShowdownEvent event;

  /// The player who generated [event].
  final ShowdownPlayer? player;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final playerName = player?.name;
    return ListTile(
      title: Text(playerName ?? event.description),
      subtitle: playerName == null ? null : Text(event.description),
      onTap: () {},
    );
  }
}
