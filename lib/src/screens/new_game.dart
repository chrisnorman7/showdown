import 'package:backstreets_widgets/extensions.dart';
import 'package:backstreets_widgets/screens.dart';
import 'package:backstreets_widgets/shortcuts.dart';
import 'package:backstreets_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showdown/showdown.dart';

class _SetConfig {
  /// Create an instance.
  const _SetConfig({required this.numberOfSets, required this.key});

  /// The number of sets.
  final int numberOfSets;

  /// THe keyboard key to use.
  final LogicalKeyboardKey key;
}

/// A screen for creating a new game.
class NewGame extends ConsumerStatefulWidget {
  /// Create an instance.
  const NewGame({super.key});

  /// Create state for this widget.
  @override
  NewGameState createState() => NewGameState();
}

/// State for [NewGame].
class NewGameState extends ConsumerState<NewGame> {
  /// The controller for the name of the left player.
  late final TextEditingController _player1NameController;

  /// The controller for the name of the right player.
  late final TextEditingController _player2NameController;

  /// The minimum points for winning the game.
  late int _winningPoints;

  /// The number of clear points.
  late int _clearPoints;

  /// The number of sets to play.
  late int _numberOfSets;

  /// Whether or not players will switch ends every set.
  late bool _switchEnds;

  /// The number of serves each player should have.
  late int _numberOfServes;

  /// Initialise state.
  @override
  void initState() {
    super.initState();
    _player1NameController = TextEditingController();
    _player2NameController = TextEditingController();
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
  Widget build(final BuildContext context) {
    final value = ref.watch(appConfigProvider);
    return value.when(
      data: (final appConfig) {
        _player1NameController.text = appConfig.player1Name;
        _player2NameController.text = appConfig.player2Name;
        _winningPoints = appConfig.winningPoints;
        _clearPoints = appConfig.clearPoints;
        _numberOfSets = appConfig.numberOfSets;
        _switchEnds = appConfig.switchEnds;
        _numberOfServes = appConfig.numberOfServes;
        _player1NameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _player1NameController.text.length,
        );
        _player2NameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _player2NameController.text.length,
        );
        return SimpleScaffold(
          title: 'New Game',
          body: CallbackShortcuts(
            bindings: {
              CrossPlatformSingleActivator(LogicalKeyboardKey.keyP):
                  () => playGame(context),
            },
            child: Form(
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    autofocus: true,
                    controller: _player1NameController,
                    decoration: const InputDecoration(
                      labelText: 'Player 1 name',
                    ),
                  ),
                  TextFormField(
                    controller: _player2NameController,
                    decoration: const InputDecoration(
                      labelText: 'Player 2 name',
                    ),
                  ),
                  ListTile(
                    title: const Text('Switch Ends'),
                    onTap:
                        () => setState(() {
                          final temp = _player1NameController.text;
                          _player1NameController.text =
                              _player2NameController.text;
                          _player2NameController.text = temp;
                        }),
                  ),
                  PerformableActionsListTile(
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
                                () => _numberOfSets = setConfig.numberOfSets,
                              ),
                          activator: CrossPlatformSingleActivator(
                            setConfig.key,
                          ),
                        ),
                    ],
                    title: const Text('Number of Sets'),
                    subtitle: Text(_numberOfSets.toString()),
                    onLongPress: () => setState(() => _numberOfSets = 1),
                  ),
                  if (_numberOfSets > 1)
                    CheckboxListTile(
                      value: _switchEnds,
                      onChanged:
                          (_) => setState(() {
                            _switchEnds = !_switchEnds;
                          }),
                      title: const Text('Switch Ends Between Sets'),
                    ),
                  IntListTile(
                    value: _numberOfServes,
                    onChanged:
                        (final value) =>
                            setState(() => _numberOfServes = value),
                    title: 'Number of Serves',
                    min: 1,
                  ),
                  IntListTile(
                    value: _winningPoints,
                    onChanged:
                        (final value) => setState(() => _winningPoints = value),
                    title: 'Winning Points',
                    min: 1,
                  ),
                  IntListTile(
                    value: _clearPoints,
                    onChanged:
                        (final value) => setState(() => _clearPoints = value),
                    title: 'Clear Points',
                    min: 1,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => playGame(context),
            tooltip: 'Start Game',
            child: const Icon(Icons.play_arrow, semanticLabel: 'Start Game'),
          ),
        );
      },
      error: ErrorScreen.withPositional,
      loading: LoadingScreen.new,
    );
  }

  /// Start the game with the current settings.
  void playGame(final BuildContext context) {
    AppConfig(
      clearPoints: _clearPoints,
      numberOfServes: _numberOfServes,
      numberOfSets: _numberOfSets,
      player1Name: _player1NameController.text,
      player2Name: _player2NameController.text,
      switchEnds: _switchEnds,
      winningPoints: _winningPoints,
    ).save();
    context.pushWidgetBuilder(
      (_) => PlayGame(
        leftPlayerName: _player1NameController.text,
        rightPlayerName: _player2NameController.text,
        winningPoints: _winningPoints,
        clearPoints: _clearPoints,
        switchEnds: _switchEnds,
        numberOfSets: _numberOfSets,
        numberOfServes: _numberOfServes,
      ),
    );
  }
}
