import 'package:flutter/material.dart';

import '../serve_number.dart';
import '../table_end.dart';
import 'custom_text.dart';

/// The central panel when the device is in landscape.
class ScorePanel extends StatelessWidget {
  /// Create an instance.
  const ScorePanel({
    required this.leftPlayerName,
    required this.leftPlayerScore,
    required this.rightPlayerName,
    required this.rightPlayerScore,
    required this.serveNumber,
    required this.tableEnd,
    required this.switchEnds,
    super.key,
  });

  /// The name of the left player.
  final String leftPlayerName;

  /// The left player's score.
  final int leftPlayerScore;

  /// The name of the right player.
  final String rightPlayerName;

  /// The right player's score.
  final int rightPlayerScore;

  /// The end which is being served from.
  final TableEnd tableEnd;

  /// The serve number.
  final ServeNumber serveNumber;

  /// The function to call to switch table ends.
  final VoidCallback switchEnds;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final servingPlayerName = switch (tableEnd) {
      TableEnd.left => leftPlayerName,
      TableEnd.right => rightPlayerName,
    };
    final serveNumberString = serveNumber.name;
    final scores = switch (tableEnd) {
      TableEnd.left => '$leftPlayerScore : $rightPlayerScore',
      TableEnd.right => '$rightPlayerScore : $leftPlayerScore',
    };
    return ListView(
      shrinkWrap: true,
      children: [
        Semantics(
          liveRegion: true,
          child: CustomText(
            "$servingPlayerName's $serveNumberString serve ($scores)",
          ),
        ),
        CustomText('$leftPlayerName: $leftPlayerScore'),
        CustomText('$rightPlayerName: $rightPlayerScore'),
        ElevatedButton(
          onPressed: switchEnds,
          child: const Icon(
            Icons.swap_calls,
            semanticLabel: 'Switch ends',
          ),
        ),
      ],
    );
  }
}
