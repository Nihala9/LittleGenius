import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = true; 
  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isAdminDarkMode') ?? true;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Dynamic Color Getters used by all screens
  Color get bgColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get cardColor => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get textColor => _isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get subTextColor => _isDarkMode ? Colors.white38 : Colors.black54;
  Color get borderColor => _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200;
}