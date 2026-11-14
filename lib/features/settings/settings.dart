import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode theme = ThemeMode.system;
  bool notifications = true;
  bool sound = true;
  int reminderMinutes = 15;
  File? _file;
  Future<void> _pending = Future.value();

  Future<void> load() async {
    _file = File(
      '${(await getApplicationSupportDirectory()).path}/preferences.json',
    );
    if (!await _file!.exists()) return;
    try {
      final data =
          jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
      theme = ThemeMode.values.firstWhere(
        (v) => v.name == data['theme'],
        orElse: () => ThemeMode.system,
      );
      notifications = data['notifications'] != false;
      sound = data['sound'] != false;
      final minutes = data['minutes'];
      if ([0, 5, 15, 30, 60].contains(minutes)) {
        reminderMinutes = minutes as int;
      }
    } on FormatException {
      /* A damaged preferences file uses safe defaults. */
    }
  }

  Future<void> update({
    ThemeMode? themeMode,
    bool? enabled,
    bool? playSound,
    int? minutes,
  }) async {
    if (themeMode != null) theme = themeMode;
    if (enabled != null) notifications = enabled;
    if (playSound != null) sound = playSound;
    if (minutes != null) reminderMinutes = minutes;
    notifyListeners();
    final content = jsonEncode({
      'theme': theme.name,
      'notifications': notifications,
      'sound': sound,
      'minutes': reminderMinutes,
    });
    _pending = _pending.catchError((Object _) {}).then((_) async {
      if (_file != null) {
        await _file!.parent.create(recursive: true);
        final temp = File('${_file!.path}.tmp');
        await temp.writeAsString(content, flush: true);
        await temp.rename(_file!.path);
      }
    });
    await _pending;
  }
}

final settingsProvider = Provider<AppSettings>((ref) {
  final settings = AppSettings();
  ref.onDispose(settings.dispose);
  return settings;
});
