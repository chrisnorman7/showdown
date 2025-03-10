import 'package:flutter/material.dart';
import 'package:showdown/showdown.dart';

/// A column for displaying [player].
class PlayerColumn extends StatelessWidget {
  /// Create an instance.
  const PlayerColumn({
    required this.player,
    required this.tableEnd,
    required this.performAction,
    super.key,
  });

  /// The player to show.
  final ShowdownPlayer player;

  /// The end of the table this column will represent.
  final TableEnd tableEnd;

  /// The function to call to perform actions.
  final PerformAction performAction;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final foulButton = FoulButton(
      addEvent: (final event) {
        performAction(
          UndoableAction(
            action: () => player.events.add(event),
            undo: () => player.events.remove(event),
          ),
        );
      },
    );
    final warningButton = WarningButton(
      addWarning: () {
        if (player.firstWarning) {
          final event = ShowdownEvent(
            points: -2,
            description: 'Foul after warning',
          );
          performAction(
            UndoableAction(
              action: () => player.events.add(event),
              undo: () => player.events.remove(event),
            ),
          );
        } else {
          performAction(
            UndoableAction(
              action: () => player.firstWarning = true,
              undo: () => player.firstWarning = false,
              endPoint: false,
            ),
          );
        }
      },
      firstWarning: player.firstWarning,
    );
    final crossAxisAlignment = switch (tableEnd) {
      TableEnd.left => CrossAxisAlignment.start,
      TableEnd.right => CrossAxisAlignment.end,
    };
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: crossAxisAlignment,
            children: switch (tableEnd) {
              TableEnd.left => [foulButton, warningButton],
              TableEnd.right => [warningButton, foulButton],
            },
          ),
        ),
        Expanded(
          child: CheckboxListTile(
            value: player.timeout,
            onChanged: (final value) {
              if (player.timeout) {
                final event = ShowdownEvent(
                  points: -2,
                  description: 'Timeout already requested',
                );
                performAction(
                  UndoableAction(
                    action: () => player.events.add(event),
                    undo: () => player.events.remove(event),
                  ),
                );
              } else {
                performAction(
                  UndoableAction(
                    action: () => player.timeout = true,
                    undo: () => player.timeout = false,
                    endPoint: false,
                  ),
                );
              }
            },
            title: const Text('Timeout'),
          ),
        ),
        Expanded(
          child: GoalButton(
            addEvent: (final event) {
              performAction(
                UndoableAction(
                  action: () => player.events.add(event),
                  undo: () => player.events.remove(event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
