import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showdown/showdown.dart';

part 'providers.g.dart';

/// Provide the app preferences.
@riverpod
Future<AppConfig> appConfig(final Ref ref) async {
  final preferences = SharedPreferencesAsync();
  final source = await preferences.getString(AppConfig.preferencesKey);
  if (source == null) {
    return AppConfig();
  }
  return AppConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
