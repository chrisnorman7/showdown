import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/shortcuts.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showdown/src/screens/play_game.dart';

class _SetConfig {
  /// Create an instance.
  const _SetConfig({required this.numberOfSets, required this.key});

  /// The number of sets.
  final int numberOfSets;

  /// THe keyboard key to use.
  final LogicalKeyboardKey key;
}

/// A screen for creating a new game.
class NewGame extends StatefulWidget {
  /// Create an instance.
  const NewGame({super.key});

  /// Create state for this widget.
  @override
  NewGameState createState() => NewGameState();
}

/// State for [NewGame].
class NewGameState extends State<NewGame> {
  /// The controller for the name of the left player.
  late final TextEditingController _player1NameController;

  /// The controller for the name of the right player.
  late final TextEditingController _player2NameController;

  /// The minimum points for winning the game.
  late int winningPoints;

  /// The number of clear points.
  late int clearPoints;

  /// The number of sets to play.
  late int numberOfSets;

  /// Whether or not players will switch ends every set.
  late bool switchEnds;

  /// The number of serves each player should have.
  late int numberOfServes;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    _player1NameController = TextEditingController(text: 'Player 1');
    _player1NameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _player1NameController.text.length,
    );
    _player2NameController = TextEditingController(text: 'Player 2');
    _player2NameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _player2NameController.text.length,
    );
    winningPoints = 11;
    clearPoints = 2;
    numberOfSets = 1;
    switchEnds = true;
    numberOfServes = 2;
  }

  /// Dispose of the widget.
  @override
  void dispose() {
    super.dispose();
    _player1NameController.dispose();
    _player2NameController.dispose();
  }

  /// Build a widget.
  @override
  Widget build(final BuildContext context) => CallbackShortcuts(
    bindings: {
      CrossPlatformSingleActivator(LogicalKeyboardKey.keyP):
          () => playGame(context),
    },
    child: SimpleScaffold(
      title: 'New Game',
      body: Form(
        child: ListView(
          shrinkWrap: true,
          children: [
            TextFormField(
              autofocus: true,
              controller: _player1NameController,
              decoration: const InputDecoration(labelText: 'Player 1 name'),
            ),
            TextFormField(
              controller: _player2NameController,
              decoration: const InputDecoration(labelText: 'Player 2 name'),
            ),
            ListTile(
              title: const Text('Switch Ends'),
              onTap:
                  () => setState(() {
                    final temp = _player1NameController.text;
                    _player1NameController.text = _player2NameController.text;
                    _player2NameController.text = temp;
                  }),
            ),
            PerformableActionsBuilder(
              actions: [
                for (final setConfig in [
                  const _SetConfig(
                    numberOfSets: 1,
                    key: LogicalKeyboardKey.digit1,
                  ),
                  const _SetConfig(
                    numberOfSets: 3,
                    key: LogicalKeyboardKey.digit3,
                  ),
                  const _SetConfig(
                    numberOfSets: 5,
                    key: LogicalKeyboardKey.digit5,
                  ),
                ])
                  PerformableAction(
                    name:
                        // ignore: lines_longer_than_80_chars
                        '${setConfig.numberOfSets} ${setConfig.numberOfSets == 1 ? "set" : "sets"}',
                    invoke:
                        () => setState(
                          () => numberOfSets = setConfig.numberOfSets,
                        ),
                    activator: CrossPlatformSingleActivator(setConfig.key),
                  ),
              ],
              builder:
                  (final builderContext, final controller) => ListTile(
                    title: const Text('Number of Sets'),
                    subtitle: Text(numberOfSets.toString()),
                    onTap: controller.toggle,
                  ),
            ),
            if (numberOfSets > 1)
              CheckboxListTile(
                value: switchEnds,
                onChanged:
                    (_) => setState(() {
                      switchEnds = !switchEnds;
                    }),
                title: const Text('Switch Ends Between Sets'),
              ),
            IntListTile(
              value: numberOfServes,
              onChanged:
                  (final value) => setState(() => numberOfServes = value),
              title: 'Number of Serves',
              min: 1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => playGame(context),
        tooltip: 'Start Game',
        child: const Icon(Icons.play_arrow, semanticLabel: 'Start Game'),
      ),
    ),
  );

  /// Start the game with the current settings.
  void playGame(final BuildContext context) => context.pushWidgetBuilder(
    (_) => PlayGame(
      leftPlayerName: _player1NameController.text,
      rightPlayerName: _player2NameController.text,
      winningPoints: winningPoints,
      clearPoints: clearPoints,
      switchEnds: switchEnds,
      numberOfSets: numberOfSets,
      numberOfServes: numberOfServes,
    ),
  );
}
