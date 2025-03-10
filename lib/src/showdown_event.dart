/// An event in a showdown game.
class ShowdownEvent implements Comparable<ShowdownEvent> {
  /// Create an instance.
  ShowdownEvent({required this.points, required this.description})
    : created = DateTime.now();

  /// The time when this event was created.
  final DateTime created;

  /// The number of points this event awards.
  ///
  /// If the points go to the opponent, then [points] should be a negative
  /// number.
  final int points;

  /// The description of this event.
  String description;

  /// Compare to [other].
  @override
  int compareTo(final ShowdownEvent other) => created.compareTo(other.created);
}
