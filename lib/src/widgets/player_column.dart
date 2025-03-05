import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/shortcuts.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showdown/showdown.dart';

/// The foul button.
class _FoulButton extends StatelessWidget {
  /// Create an instance.
  const _FoulButton({required this.addEvent});

  /// The function to call to add the event.
  final ValueChanged<ShowdownEvent> addEvent;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => IconButton(
    onPressed: () => addEvent(ShowdownEvent(points: -1, description: 'Foul')),
    icon: const Icon(Icons.sports_kabaddi, semanticLabel: 'Foul'),
  );
}

/// The warning button.
class _WarningButton extends StatelessWidget {
  /// Create an instance.
  const _WarningButton({required this.addWarning, required this.firstWarning});

  /// The function to call to add the warning.
  final VoidCallback addWarning;

  /// Whether the player is on their first warning or not.
  final bool firstWarning;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => Semantics(
    checked: firstWarning,
    child: IconButton(
      onPressed: addWarning,
      icon: Icon(
        Icons.warning,
        semanticLabel: 'Issue warning',
        color: firstWarning ? Colors.yellow : Colors.grey,
      ),
    ),
  );
}

/// The goal button
class _GoalButton extends StatelessWidget {
  /// Create an instance.
  const _GoalButton({required this.addEvent});

  /// The function to call to add the event.
  final ValueChanged<ShowdownEvent> addEvent;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => IconButton(
    onPressed: () => addEvent(ShowdownEvent(points: 2, description: 'Goal')),
    icon: const Icon(Icons.sports_soccer, semanticLabel: 'Goal'),
  );
}

/// A column for displaying [player].
class PlayerColumn extends StatelessWidget {
  /// Create an instance.
  const PlayerColumn({
    required this.player,
    required this.tableEnd,
    required this.updateEvents,
    required this.letEvent,
    super.key,
  });

  /// The player to show.
  final ShowdownPlayer player;

  /// The cross axis alignment to use.
  final TableEnd tableEnd;

  /// The function to call to add points.
  final VoidCallback updateEvents;

  /// The function to call for a let.
  final VoidCallback letEvent;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) {
    final foulButton = _FoulButton(
      addEvent: (final value) {
        player.events.add(value);
        updateEvents();
      },
    );
    final warningButton = _WarningButton(
      addWarning: () {
        if (player.firstWarning) {
          player.events.add(
            ShowdownEvent(points: -2, description: 'Foul after warning'),
          );
          updateEvents();
        } else {
          player.firstWarning = true;
          letEvent();
        }
      },
      firstWarning: player.firstWarning,
    );
    final int points;
    final events = player.events.where((final event) => event.points > 0);
    if (events.isEmpty) {
      points = 0;
    } else {
      points = events
          .map((final event) => event.points)
          .reduce((final value, final element) => value + element);
    }
    final crossAxisAlignment = switch (tableEnd) {
      TableEnd.left => CrossAxisAlignment.start,
      TableEnd.right => CrossAxisAlignment.end,
    };
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(child: Focus(child: Text('${player.name} ($points)'))),
        Expanded(
          flex: 7,
          child: ListView.builder(
            itemBuilder: (final context, final index) {
              final event = player.events[index];
              return PerformableActionsListTile(
                actions: [
                  PerformableAction(
                    name: 'Rename',
                    invoke:
                        () => context.pushWidgetBuilder(
                          (final innerContext) => GetText(
                            onDone: (final value) {
                              innerContext.pop();
                              event.description = value;
                              updateEvents();
                            },
                          ),
                        ),
                    activator: CrossPlatformSingleActivator(
                      LogicalKeyboardKey.keyR,
                    ),
                  ),
                  PerformableAction(
                    name: 'Delete',
                    invoke:
                        () => context.showConfirmMessage(
                          message: 'Delete this event?',
                          title: 'Delete Event',
                          yesCallback: () {
                            player.events.removeAt(index);
                            updateEvents();
                          },
                        ),
                    activator: deleteShortcut,
                  ),
                ],
                title: Text(event.description),
              );
            },
            itemCount: player.events.length,
            shrinkWrap: true,
          ),
        ),
        Row(
          crossAxisAlignment: crossAxisAlignment,
          children: switch (tableEnd) {
            TableEnd.left => [foulButton, warningButton],
            TableEnd.right => [warningButton, foulButton],
          },
        ),
        CheckboxListTile(
          value: player.timeout,
          onChanged: (final value) {
            if (player.timeout) {
              player.events.add(
                ShowdownEvent(
                  points: -2,
                  description: 'Timeout already requested',
                ),
              );
              updateEvents();
            } else {
              player.timeout = true;
              letEvent();
            }
          },
          title: const Text('Timeout'),
        ),
        _GoalButton(
          addEvent: (final value) {
            player.events.add(value);
            updateEvents();
          },
        ),
      ],
    );
  }
}
