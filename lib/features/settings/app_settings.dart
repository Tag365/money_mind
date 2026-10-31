import 'package:flutter/material.dart';
import 'package:money_mind/database/database_service.dart';

const _theme = 'theme';
const _appLock = 'app_lock';

Stream<ThemeMode> watchThemeMode() => DatabaseService.instance
    .watchSetting(_theme)
    .map((name) => ThemeMode.values.asNameMap()[name] ?? ThemeMode.system);

Future<void> setThemeMode(ThemeMode mode) =>
    DatabaseService.instance.setSetting(_theme, mode.name);

Stream<bool> watchAppLock() => DatabaseService.instance
    .watchSetting(_appLock)
    .map((value) => value == 'true');

Future<void> setAppLock(bool on) =>
    DatabaseService.instance.setSetting(_appLock, '$on');
