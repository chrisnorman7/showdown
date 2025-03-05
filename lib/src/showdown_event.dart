/// An event in a showdown game.
class ShowdownEvent {
  /// Create an instance.
  ShowdownEvent({required this.points, required this.description});

  /// The number of points this event awards.
  ///
  /// If the points go to the opponent, then [points] should be a negative
  /// number.
  final int points;

  /// The description of this event.
  String description;
}
