import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeService() { _loadTheme(); }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isAdminDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Branding: Ocean Blue (#2872A1) and Cloudy Sky (#CBDDE9)
  Color get bgColor => _isDarkMode ? const Color(0xFF0F172A) : AppColors.backgroundWhite;
  Color get sidebarColor => _isDarkMode ? const Color(0xFF1E293B) : AppColors.oceanBlue;
  Color get cardColor => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get textColor => _isDarkMode ? Colors.white : AppColors.textDark;
  Color get subTextColor => _isDarkMode ? Colors.white38 : Colors.black54;
  Color get borderColor => _isDarkMode ? Colors.white10 : AppColors.cloudySky;
}