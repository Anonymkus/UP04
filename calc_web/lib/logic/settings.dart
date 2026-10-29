import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._();
  static final instance = Settings._();

  SharedPreferences? _prefs;
  final darkMode = ValueNotifier<bool>(false);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    darkMode.value = _prefs!.getBool('darkMode') ?? false;
  }

  void toggleTheme() {
    darkMode.value = !darkMode.value;
    _prefs?.setBool('darkMode', darkMode.value);
  }

  String? get lastFrom => _prefs?.getString('lastFrom');
  String? get lastTo => _prefs?.getString('lastTo');

  void savePair(String from, String to) {
    _prefs?.setString('lastFrom', from);
    _prefs?.setString('lastTo', to);
  }
}
