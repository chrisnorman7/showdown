import 'dart:async';

import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/shortcuts.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';
import 'package:showdown/showdown.dart';

/// The type of a perform action function.
typedef PerformAction = void Function(UndoableAction action);

/// A screen for playing a game.
class PlayGame extends StatefulWidget {
  /// Create an instance.
  const PlayGame({
    required this.leftPlayerName,
    required this.rightPlayerName,
    required this.winningPoints,
    required this.clearPoints,
    required this.switchEnds,
    required this.numberOfSets,
    required this.numberOfServes,
    super.key,
  });

  /// The name of the left player.
  final String leftPlayerName;

  /// The name of the right player.
  final String rightPlayerName;

  /// The number of points to win.
  final int winningPoints;

  /// The number of clear points.
  final int clearPoints;

  /// The number of sets to play.
  final int numberOfSets;

  /// The number of serves each player will have before the ball switches ends.
  final int numberOfServes;

  /// Whether or not players must switch ends between sets.
  final bool switchEnds;

  /// Create state for this widget.
  @override
  PlayGameState createState() => PlayGameState();
}

/// State for [PlayGame].
class PlayGameState extends State<PlayGame> {
  /// An action which can be undone.
  UndoableAction? _action;

  /// The left player for the game.
  late ShowdownPlayer leftPlayer;

  /// The right player.
  late ShowdownPlayer rightPlayer;

  /// The current set number.
  late int setNumber;

  /// The end of the table which will start the game.
  TableEnd? _startingEnd;

  /// The end of the table which is currently serving.
  late TableEnd servingEnd;

  /// The number of the serve which is happening.
  late int serveNumber;

  /// The end of the table which is not serving.
  TableEnd get receivingEnd => switch (servingEnd) {
    TableEnd.left => TableEnd.right,
    TableEnd.right => TableEnd.left,
  };

  /// Whether ens have been switched yet or not.
  late bool endsSwitched;

  /// The number of seconds left on the timer.
  late int secondsRemaining;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    leftPlayer = ShowdownPlayer(name: widget.leftPlayerName, events: []);
    rightPlayer = ShowdownPlayer(name: widget.rightPlayerName, events: []);
    setNumber = 1;
    serveNumber = 1;
    endsSwitched = false;
    secondsRemaining = 0;
  }

  /// Build a widget.
  @override
  Widget build(final BuildContext context) {
    if (secondsRemaining > 0) {
      Timer(
        const Duration(seconds: 1),
        () => setState(() => secondsRemaining -= 1),
      );
      return DefaultTextStyle(
        style: const TextStyle(fontSize: 32),
        child: SimpleScaffold(
          title: 'Timer',
          body: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                autofocus: true,
                title: const Text('Remaining seconds'),
                subtitle: Semantics(
                  liveRegion: true,
                  child: Text('$secondsRemaining'),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      );
    }
    final startingEnd = _startingEnd;
    if (startingEnd == null) {
      return SimpleScaffold(
        title: 'Select Starting Player',
        body: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              autofocus: true,
              title: Text('${TableEnd.left.name.titleCase} player'),
              subtitle: Text(widget.leftPlayerName),
              onTap:
                  () => setState(() {
                    _startingEnd = TableEnd.left;
                    servingEnd = TableEnd.left;
                  }),
            ),
            ListTile(
              title: Text('${TableEnd.right.name.titleCase} player'),
              subtitle: Text(widget.rightPlayerName),
              onTap:
                  () => setState(() {
                    _startingEnd = TableEnd.right;
                    servingEnd = TableEnd.right;
                  }),
            ),
          ],
        ),
      );
    }
    final winningEnd = getWinningEnd();
    if (winningEnd != null) {
      final losingEnd = switch (winningEnd) {
        TableEnd.left => TableEnd.right,
        TableEnd.right => TableEnd.left,
      };
      final winningPlayer = switch (winningEnd) {
        TableEnd.left => leftPlayer,
        TableEnd.right => rightPlayer,
      };
      return Cancel(
        child: SimpleScaffold(
          title: 'Game Over',
          body: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                autofocus: true,
                title: Text('Winner of set $setNumber'),
                subtitle: Text(winningPlayer.name),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Scores'),
                subtitle: Text(
                  '${getPoints(winningEnd)} / ${getPoints(losingEnd)}',
                ),
                onTap: () {},
              ),
            ],
          ),
          floatingActionButton:
              setNumber >= widget.numberOfSets
                  ? null
                  : FloatingActionButton(
                    onPressed: () {
                      setNumber++;
                      final oldLeftPlayer = rightPlayer;
                      leftPlayer = rightPlayer;
                      rightPlayer = oldLeftPlayer;
                      startSet();
                    },
                    tooltip: 'Next Set',
                    child: const Icon(Icons.arrow_forward),
                  ),
        ),
      );
    }
    final servingPlayer = switch (servingEnd) {
      TableEnd.left => leftPlayer,
      TableEnd.right => rightPlayer,
    };
    final shortcuts = <GameShortcut>[
      GameShortcut(
        title: 'Left player foul',
        shortcut: GameShortcutsShortcut.digit1,
        onStart: (final innerContext) {
          addEvent(leftPlayer, ShowdownEvent(points: -1, description: 'Foul'));
        },
      ),
      GameShortcut(
        title: 'Left player goal',
        shortcut: GameShortcutsShortcut.digit7,
        onStart: (final innerContext) {
          addEvent(leftPlayer, ShowdownEvent(points: 2, description: 'Goal'));
        },
      ),
      GameShortcut(
        title: 'Left player warning',
        shortcut: GameShortcutsShortcut.digit2,
        onStart: (final innerContext) {
          if (leftPlayer.firstWarning) {
            addEvent(
              leftPlayer,
              ShowdownEvent(points: -2, description: 'Foul after warning'),
            );
          } else {
            performAction(
              UndoableAction(
                action: () => leftPlayer.firstWarning = true,
                undo: () => leftPlayer.firstWarning = false,
                endPoint: false,
              ),
            );
            innerContext.announce('First warning for ${leftPlayer.name}.');
          }
        },
      ),
      GameShortcut(
        title: 'Left player timeout',
        shortcut: GameShortcutsShortcut.digit8,
        onStart: (final innerContext) {
          if (leftPlayer.timeout) {
            addEvent(
              leftPlayer,
              ShowdownEvent(points: -2, description: 'Timeout already called'),
            );
          } else {
            performAction(
              UndoableAction(
                action: () => leftPlayer.timeout = true,
                undo: () => leftPlayer.timeout = false,
                endPoint: false,
              ),
            );
            innerContext.announce('Timeout called for ${leftPlayer.name}.');
          }
        },
      ),
      GameShortcut(
        title: 'Announce left player points',
        shortcut: GameShortcutsShortcut.digit3,
        onStart:
            (final innerContext) => innerContext.announce(
              '${leftPlayer.name}: ${getPoints(TableEnd.left)}',
            ),
      ),
      GameShortcut(
        title: 'Right player foul',
        shortcut: GameShortcutsShortcut.digit6,
        onStart: (final innerContext) {
          addEvent(rightPlayer, ShowdownEvent(points: -1, description: 'Foul'));
        },
      ),
      GameShortcut(
        title: 'Right player goal',
        shortcut: GameShortcutsShortcut.keyB,
        onStart: (final innerContext) {
          addEvent(rightPlayer, ShowdownEvent(points: 2, description: 'Goal'));
        },
      ),
      GameShortcut(
        title: 'Right player warning',
        shortcut: GameShortcutsShortcut.digit5,
        onStart: (final innerContext) {
          if (rightPlayer.firstWarning) {
            addEvent(
              rightPlayer,
              ShowdownEvent(points: -2, description: 'Foul after warning'),
            );
          } else {
            performAction(
              UndoableAction(
                action: () => rightPlayer.firstWarning = true,
                undo: () => rightPlayer.firstWarning = false,
                endPoint: false,
              ),
            );
            innerContext.announce('First warning for ${rightPlayer.name}.');
          }
        },
      ),
      GameShortcut(
        title: 'Right player timeout',
        shortcut: GameShortcutsShortcut.keyA,
        onStart: (final innerContext) {
          if (rightPlayer.timeout) {
            addEvent(
              rightPlayer,
              ShowdownEvent(points: -2, description: 'Timeout already called'),
            );
          } else {
            performAction(
              UndoableAction(
                action: () => rightPlayer.timeout = true,
                undo: () => rightPlayer.timeout = false,
                endPoint: false,
              ),
            );
            innerContext.announce('Timeout called for ${rightPlayer.name}.');
          }
        },
      ),
      GameShortcut(
        title: 'Announce right player points',
        shortcut: GameShortcutsShortcut.digit4,
        onStart:
            (final innerContext) => innerContext.announce(
              '${rightPlayer.name}: ${getPoints(TableEnd.right)}',
            ),
      ),
      GameShortcut(
        title: 'Sixty seconds timer',
        shortcut: GameShortcutsShortcut.digit9,
        onStart: (final innerContext) {
          setState(() {
            secondsRemaining = 60;
          });
        },
      ),
      GameShortcut(
        title: 'Undo the most recent action.',
        shortcut: GameShortcutsShortcut.digit0,
        onStart: (_) => undoAction(),
      ),
      GameShortcut(
        title: 'End the game',
        shortcut: GameShortcutsShortcut.escape,
        onStart: (final innerContext) => innerContext.pop(),
      ),
    ];
    shortcuts.add(
      GameShortcut(
        title: 'Keyboard help',
        shortcut: GameShortcutsShortcut.slash,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart:
            (final innerContext) => innerContext.pushWidgetBuilder(
              (_) => GameShortcutsHelpScreen(shortcuts: shortcuts),
            ),
      ),
    );
    final bottomRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: PlayerColumn(
            player: leftPlayer,
            tableEnd: TableEnd.left,
            performAction: performAction,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              IconButton(
                onPressed: () => setState(() => secondsRemaining = 60),
                icon: const Icon(
                  Icons.timer,
                  semanticLabel: 'Start 60-second count down',
                ),
              ),
              Semantics(
                liveRegion: true,
                child: Focus(
                  autofocus: true,
                  child: Text(
                    "${servingPlayer.name}'s ${serveNumber.ordinal()} serve: ${getPoints(servingEnd)} / ${getPoints(receivingEnd)}",
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: PlayerColumn(
            player: rightPlayer,
            tableEnd: TableEnd.right,
            performAction: performAction,
          ),
        ),
      ],
    );
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 24),
      child: Actions(
        actions: {
          UndoTextIntent: CallbackAction(onInvoke: (_) => undoAction()),
        },
        child: GameShortcuts(
          shortcuts: shortcuts,
          autofocus: false,
          canRequestFocus: false,
          child: SimpleScaffold(
            title: 'Set $setNumber / ${widget.numberOfSets}',
            body: OrientationBuilder(
              builder: (final context, final orientation) {
                switch (orientation) {
                  case Orientation.portrait:
                    final events = [...leftPlayer.events, ...rightPlayer.events]
                      ..sort();
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemBuilder: (final context, final index) {
                              final event = events[index];
                              return ShowdownEventListTile(
                                event: event,
                                player:
                                    leftPlayer.events.contains(event)
                                        ? leftPlayer
                                        : rightPlayer,
                              );
                            },
                            itemCount: events.length,
                            shrinkWrap: true,
                          ),
                        ),
                        const Divider(height: 12.0),
                        bottomRow,
                      ],
                    );
                  case Orientation.landscape:
                    return Column(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: ListView.builder(
                                  itemBuilder:
                                      (final context, final index) =>
                                          ShowdownEventListTile(
                                            event: leftPlayer.events[index],
                                          ),
                                  itemCount: leftPlayer.events.length,
                                  shrinkWrap: true,
                                ),
                              ),
                              const VerticalDivider(),
                              Expanded(
                                flex: 5,
                                child: ListView.builder(
                                  itemBuilder:
                                      (final context, final index) =>
                                          ShowdownEventListTile(
                                            event: rightPlayer.events[index],
                                          ),
                                  itemCount: rightPlayer.events.length,
                                  shrinkWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 12.0),
                        Expanded(flex: 3, child: bottomRow),
                      ],
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Undo the most recent action.
  void undoAction() {
    final action = _action;
    if (action != null) {
      action.undo();
      _action = null;
      context.announce('Undone last action.');
      if (action.endPoint) {
        if (serveNumber == 1) {
          servingEnd = receivingEnd;
          serveNumber = widget.numberOfServes;
        } else {
          serveNumber -= 1;
        }
      }
      setState(() {});
    } else {
      context.announce('Nothing to undo.');
    }
  }

  /// Set values for a new set.
  void startSet() {
    _action = null;
    servingEnd = _startingEnd!;
    leftPlayer.events.clear();
    rightPlayer.events.clear();
    setState(() {});
  }

  /// Get the points for the given [end] of the table.
  int getPoints(final TableEnd end) {
    final Iterable<ShowdownEvent> ownedEvents;
    final Iterable<ShowdownEvent> opponentEvents;
    switch (end) {
      case TableEnd.left:
        ownedEvents = leftPlayer.events.where((final e) => e.points > 0);
        opponentEvents = rightPlayer.events.where((final e) => e.points < 0);
      case TableEnd.right:
        ownedEvents = rightPlayer.events.where((final e) => e.points > 0);
        opponentEvents = leftPlayer.events.where((final e) => e.points < 0);
    }
    final events = [...ownedEvents, ...opponentEvents];
    if (events.isEmpty) {
      return 0;
    }
    return events
        .map<int>((final event) => event.points.abs())
        .reduce((final value, final element) => value + element);
  }

  /// Return the winning end, if any.
  TableEnd? getWinningEnd() {
    final leftPoints = getPoints(TableEnd.left);
    final rightPoints = getPoints(TableEnd.right);
    if (leftPoints >= widget.winningPoints &&
        leftPoints - rightPoints >= widget.clearPoints) {
      return TableEnd.left;
    } else if (rightPoints >= widget.winningPoints &&
        rightPoints - leftPoints >= widget.clearPoints) {
      return TableEnd.right;
    }
    return null;
  }

  /// The function to call when the point has ended.
  void endPoint() {
    if (serveNumber >= widget.numberOfServes) {
      serveNumber = 1;
      if (widget.switchEnds) {
        servingEnd = receivingEnd;
      }
    } else {
      serveNumber++;
    }
    final halfWay =
        (widget.winningPoints / 2).floor() + (widget.winningPoints % 2);
    if (widget.numberOfSets > 1 &&
        setNumber == widget.numberOfSets &&
        widget.switchEnds &&
        !endsSwitched &&
        (getPoints(TableEnd.left) >= halfWay ||
            getPoints(TableEnd.right) >= halfWay)) {
      endsSwitched = true;
      final oldPlayer = rightPlayer;
      rightPlayer = leftPlayer;
      leftPlayer = oldPlayer;
      context.showMessage(message: 'Switch ends.');
    }
    setState(() {});
  }

  /// Add [event] as an undoable action.
  void addEvent(final ShowdownPlayer player, final ShowdownEvent event) {
    context.announce('${player.name} ${event.description}');
    performAction(
      UndoableAction(
        action: () => player.events.add(event),
        undo: () => player.events.remove(event),
      ),
    );
  }

  /// Perform [action].
  void performAction(final UndoableAction action) {
    action.action();
    _action = action;
    if (action.endPoint) {
      endPoint();
    } else {
      setState(() {});
    }
  }
}
