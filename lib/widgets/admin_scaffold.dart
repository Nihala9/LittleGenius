import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../screens/admin/admin_category_screen.dart'; 
import '../screens/admin/concept_manager.dart'; // Needed for dynamic navigation

class AdminScaffold extends StatelessWidget {
  final String title;
  final List<String> breadcrumbs;
  final Widget body;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.breadcrumbs,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: theme.bgColor,
      drawer: _buildDrawer(context, theme),
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textColor,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nightlight_round, color: AppColors.accentOrange),
            onPressed: () => theme.toggleTheme(),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClickableBreadcrumbs(context, theme),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildClickableBreadcrumbs(BuildContext context, ThemeService theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: List.generate(breadcrumbs.length, (index) {
          bool isLast = index == breadcrumbs.length - 1;
          String label = breadcrumbs[index];

          return Row(
            children: [
              InkWell(
                onTap: isLast ? null : () => _navigateViaBreadcrumb(context, label, index),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isLast ? AppColors.oceanBlue : theme.subTextColor,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                    decoration: isLast ? TextDecoration.none : TextDecoration.underline,
                  ),
                ),
              ),
              if (!isLast) Icon(Icons.chevron_right, size: 14, color: theme.subTextColor),
            ],
          );
        }),
      ),
    );
  }

  // --- IMPROVED DYNAMIC NAVIGATION LOGIC ---
  void _navigateViaBreadcrumb(BuildContext context, String label, int index) {
    if (index == 0) { 
      // Always "Home"
      Navigator.pushNamedAndRemoveUntil(context, '/admin_dashboard', (r) => false);
    } 
    else if (index == 1) { 
      // Always "Categories"
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()));
    } 
    else if (index == 2) { 
      // DYNAMIC: This is the Category Name (e.g., Alphabets, Animals)
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (c) => ConceptManagerScreen(selectedCategory: label)
      ));
    }
  }

  Widget _buildDrawer(BuildContext context, ThemeService theme) {
    return Drawer(
      backgroundColor: theme.sidebarColor,
      child: Column(
        children: [
          const DrawerHeader(child: Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 50))),
          _drawerTile(Icons.dashboard, "Dashboard", () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          }),
          _drawerTile(Icons.category, "Lesson Manager", () {
            Navigator.pop(context);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminCategoryScreen()));
          }),
          _drawerTile(Icons.settings, "Settings", () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/admin_settings');
          }),
          const Spacer(),
          _drawerTile(Icons.logout, "Logout", () {
            Navigator.pushReplacementNamed(context, '/landing');
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData i, String l, VoidCallback onTap) {
    return ListTile(
      leading: Icon(i, color: Colors.white70, size: 22),
      title: Text(l, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: onTap,
    );
  }
}