import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString('app_locale') ?? 'en';
      _locale = Locale(savedLocale);
      notifyListeners();
    } catch (e) {
      print('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(String languageCode) async {
    try {
      _locale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', languageCode);
      notifyListeners();
    } catch (e) {
      print('Error setting locale: $e');
    }
  }

  void toggleLanguage() {
    final newLanguage = _locale.languageCode == 'en' ? 'ms' : 'en';
    setLocale(newLanguage);
  }
}
