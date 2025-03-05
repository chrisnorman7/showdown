import 'package:showdown/showdown.dart';

/// A player in a game.
class ShowdownPlayer {
  /// Creates a new player with the given name.
  ShowdownPlayer({
    required this.name,
    required this.events,
    this.firstWarning = false,
    this.timeout = false,
  });

  /// The name of this player.
  final String name;

  /// The events this player has generated.
  final List<ShowdownEvent> events;

  /// Whether this player has received their first warning.
  bool firstWarning;

  /// Whether this player has requested a timeout this set.
  bool timeout;
}
