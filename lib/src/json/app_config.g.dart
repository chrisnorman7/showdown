// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => AppConfig(
  player1Name: json['player1Name'] as String? ?? 'Player 1',
  player2Name: json['player2Name'] as String? ?? 'Player 2',
  numberOfSets: (json['numberOfSets'] as num?)?.toInt() ?? 1,
  numberOfServes: (json['numberOfServes'] as num?)?.toInt() ?? 2,
  switchEnds: json['switchEnds'] as bool? ?? true,
  winningPoints: (json['winningPoints'] as num?)?.toInt() ?? 11,
  clearPoints: (json['clearPoints'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'player1Name': instance.player1Name,
  'player2Name': instance.player2Name,
  'numberOfSets': instance.numberOfSets,
  'numberOfServes': instance.numberOfServes,
  'switchEnds': instance.switchEnds,
  'winningPoints': instance.winningPoints,
  'clearPoints': instance.clearPoints,
};
