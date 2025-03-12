import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_config.g.dart';

/// App configuration.
@JsonSerializable()
class AppConfig {
  /// Create an instance.
  const AppConfig({
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
    this.numberOfSets = 1,
    this.numberOfServes = 2,
    this.switchEnds = true,
    this.winningPoints = 11,
    this.clearPoints = 2,
  });

  /// Create an instance from a JSON object.
  factory AppConfig.fromJson(final Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// The preferences key to use.
  @JsonKey(includeFromJson: false, includeToJson: false)
  static const preferencesKey = 'showdown_app_config';

  /// The name of player 1.
  final String player1Name;

  /// The name of player 2.
  final String player2Name;

  /// The number of sets to play.
  final int numberOfSets;

  /// The number of serves for each player.
  final int numberOfServes;

  /// Whether to switch ends between sets.
  final bool switchEnds;

  /// The number of points to win.
  final int winningPoints;

  /// The number of clear points.
  final int clearPoints;

  /// Convert an instance to JSON.
  Map<String, dynamic> toJson() => _$AppConfigToJson(this);

  /// Save this instance.
  Future<void> save() {
    final source = jsonEncode(this);
    final preferences = SharedPreferencesAsync();
    return preferences.setString(preferencesKey, source);
  }
}
