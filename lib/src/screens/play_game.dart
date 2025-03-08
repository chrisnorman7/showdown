import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/shortcuts.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:recase/recase.dart';
import 'package:showdown/showdown.dart';

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

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    leftPlayer = ShowdownPlayer(name: widget.leftPlayerName, events: []);
    rightPlayer = ShowdownPlayer(name: widget.rightPlayerName, events: []);
    setNumber = 1;
    serveNumber = 1;
    endsSwitched = false;
  }

  /// Build a widget.
  @override
  Widget build(final BuildContext context) {
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
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          leftPlayer.events.add(ShowdownEvent(points: -1, description: 'Foul'));
          innerContext.announce('${leftPlayer.name} foul.');
          endPoint();
        },
      ),
      GameShortcut(
        title: 'Left player goal',
        shortcut: GameShortcutsShortcut.digit2,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          leftPlayer.events.add(ShowdownEvent(points: 2, description: 'Goal'));
          innerContext.announce('${leftPlayer.name} goal.');
          endPoint();
        },
      ),
      GameShortcut(
        title: 'Left player warning',
        shortcut: GameShortcutsShortcut.digit3,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          if (leftPlayer.firstWarning) {
            leftPlayer.events.add(
              ShowdownEvent(points: -2, description: 'Foul after warning'),
            );
            innerContext.announce('Second warning for ${leftPlayer.name}.');
            endPoint();
          } else {
            leftPlayer.firstWarning = true;
            innerContext.announce('First warning for ${leftPlayer.name}.');
            setState(() {});
          }
        },
      ),
      GameShortcut(
        title: 'Left player timeout',
        shortcut: GameShortcutsShortcut.digit4,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          if (leftPlayer.timeout) {
            leftPlayer.events.add(
              ShowdownEvent(points: -2, description: 'Timeout already called'),
            );
            innerContext.announce(
              'Timeout already called for ${leftPlayer.name}.',
            );
            endPoint();
          } else {
            leftPlayer.timeout = true;
            innerContext.announce('Timeout called for ${leftPlayer.name}.');
            setState(() {});
          }
        },
      ),
      GameShortcut(
        title: 'Announce left player points',
        shortcut: GameShortcutsShortcut.digit5,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart:
            (final innerContext) => innerContext.announce(
              '${leftPlayer.name}: ${getPoints(TableEnd.left)}',
            ),
      ),
      GameShortcut(
        title: 'Right player foul',
        shortcut: GameShortcutsShortcut.digit0,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          rightPlayer.events.add(
            ShowdownEvent(points: -1, description: 'Foul'),
          );
          innerContext.announce('${rightPlayer.name} foul.');
          endPoint();
        },
      ),
      GameShortcut(
        title: 'Right player goal',
        shortcut: GameShortcutsShortcut.digit9,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          rightPlayer.events.add(ShowdownEvent(points: 2, description: 'Goal'));
          innerContext.announce('${rightPlayer.name} goal.');
          endPoint();
        },
      ),
      GameShortcut(
        title: 'Right player warning',
        shortcut: GameShortcutsShortcut.digit8,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          if (rightPlayer.firstWarning) {
            rightPlayer.events.add(
              ShowdownEvent(points: -2, description: 'Foul after warning'),
            );
            innerContext.announce('Second warning for ${rightPlayer.name}.');
            endPoint();
          } else {
            rightPlayer.firstWarning = true;
            innerContext.announce('First warning for ${rightPlayer.name}.');
            setState(() {});
          }
        },
      ),
      GameShortcut(
        title: 'Right player timeout',
        shortcut: GameShortcutsShortcut.digit7,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart: (final innerContext) {
          if (rightPlayer.timeout) {
            rightPlayer.events.add(
              ShowdownEvent(points: -2, description: 'Timeout already called'),
            );
            innerContext.announce(
              'Timeout already called for ${rightPlayer.name}.',
            );
            endPoint();
          } else {
            rightPlayer.timeout = true;
            innerContext.announce('Timeout called for ${rightPlayer.name}.');
            setState(() {});
          }
        },
      ),
      GameShortcut(
        title: 'Announce right player points',
        shortcut: GameShortcutsShortcut.digit6,
        controlKey: useControlKey,
        metaKey: useMetaKey,
        onStart:
            (final innerContext) => innerContext.announce(
              '${rightPlayer.name}: ${getPoints(TableEnd.right)}',
            ),
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
    return GameShortcuts(
      shortcuts: shortcuts,
      autofocus: false,
      canRequestFocus: false,
      child: SimpleScaffold(
        title: 'Set $setNumber / ${widget.numberOfSets}',
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: PlayerColumn(
                player: leftPlayer,
                tableEnd: TableEnd.left,
                updateEvents: endPoint,
                letEvent: () => setState(() {}),
              ),
            ),
            Expanded(
              flex: 2,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: ListTile(
                      autofocus: true,
                      title: Text(
                        // ignore: lines_longer_than_80_chars
                        "${servingPlayer.name}'s ${serveNumber.ordinal()} serve",
                      ),
                      subtitle: Text(
                        '${getPoints(servingEnd)} / ${getPoints(receivingEnd)}',
                      ),
                      onTap: () {},
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
                updateEvents: endPoint,
                letEvent: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Set values for a new set.
  void startSet() {
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
    if (widget.numberOfSets >= 5 &&
        setNumber == 5 &&
        widget.switchEnds &&
        !endsSwitched &&
        (getPoints(TableEnd.left) >= 6 || getPoints(TableEnd.right) >= 6)) {
      endsSwitched = true;
      final oldPlayer = rightPlayer;
      rightPlayer = leftPlayer;
      leftPlayer = oldPlayer;
      context.showMessage(message: 'Switch ends.');
    }
    setState(() {});
  }
}
