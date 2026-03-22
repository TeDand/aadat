import 'package:aadat/data/repositories/habit_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide preferences (theme, habits defaults, UI).
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel() {
    _load();
  }

  ThemeMode _themeMode = ThemeMode.system;
  double _textScale = 1.0;
  HabitRecurrence _defaultHabitRecurrence = HabitRecurrence.daily;
  bool _useHaptics = true;
  bool _confirmBeforeDelete = true;

  ThemeMode get themeMode => _themeMode;

  /// Multiplier for app text size (0.9 / 1.0 / 1.1).
  double get textScale => _textScale;

  HabitRecurrence get defaultHabitRecurrence => _defaultHabitRecurrence;

  bool get useHaptics => _useHaptics;

  bool get confirmBeforeDelete => _confirmBeforeDelete;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final rawTheme = p.getString(_themeKey);
    if (rawTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == rawTheme,
        orElse: () => ThemeMode.system,
      );
    }
    final rawScale = p.getString(_textScaleKey);
    if (rawScale != null) {
      _textScale = double.tryParse(rawScale) ?? 1.0;
    }
    final rawRec = p.getString(_defaultRecurrenceKey);
    if (rawRec != null) {
      _defaultHabitRecurrence = HabitRecurrence.values.firstWhere(
        (e) => e.name == rawRec,
        orElse: () => HabitRecurrence.daily,
      );
    }
    _useHaptics = p.getBool(_hapticsKey) ?? true;
    _confirmBeforeDelete = p.getBool(_confirmDeleteKey) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeKey, mode.name);
  }

  Future<void> setTextScale(double value) async {
    if (_textScale == value) return;
    _textScale = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_textScaleKey, value.toString());
  }

  Future<void> setDefaultHabitRecurrence(HabitRecurrence r) async {
    if (_defaultHabitRecurrence == r) return;
    _defaultHabitRecurrence = r;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_defaultRecurrenceKey, r.name);
  }

  Future<void> setUseHaptics(bool value) async {
    if (_useHaptics == value) return;
    _useHaptics = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_hapticsKey, value);
  }

  Future<void> setConfirmBeforeDelete(bool value) async {
    if (_confirmBeforeDelete == value) return;
    _confirmBeforeDelete = value;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_confirmDeleteKey, value);
  }

  static const _themeKey = 'app_theme_mode';
  static const _textScaleKey = 'app_text_scale';
  static const _defaultRecurrenceKey = 'default_habit_recurrence';
  static const _hapticsKey = 'use_haptics';
  static const _confirmDeleteKey = 'confirm_before_delete_habit';
}
