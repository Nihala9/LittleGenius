import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../utils/app_colors.dart';
import '../screens/parent/child_insights_screen.dart'; // REQUIRED IMPORT
import '../screens/parent/screen_time_settings.dart'; // REQUIRED IMPORT

class ParentScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final ChildProfile child;
  final String activeRoute;

  const ParentScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.child,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBEE),
      appBar: AppBar(
        title: Text(title.toUpperCase(), 
            style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ultraViolet,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: _buildSidebar(context),
      body: body,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.ultraViolet),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(child.avatarUrl),
            ),
            accountName: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("Class: ${child.childClass}", style: const TextStyle(color: Colors.white70)),
          ),

          // GROUP 1: MAIN NAVIGATION
          _sidebarItem(context, Icons.dashboard_rounded, "Overview", "overview"),
          _sidebarItem(context, Icons.analytics_rounded, "Learning Reports", "reports"),
          _sidebarItem(context, Icons.timer_rounded, "Time Limits", "limits"),

          const Divider(),

          // GROUP 2: MANAGEMENT
          _sidebarItem(context, Icons.swap_horizontal_circle_rounded, "Switch Profile", "switch"),
          _sidebarItem(context, Icons.person_add_alt_1_rounded, "Add New Child", "add"),

          const Spacer(),

          // GROUP 3: SUPPORT
          _sidebarItem(context, Icons.help_outline_rounded, "Help Center", "help"),
          _sidebarItem(context, Icons.logout_rounded, "Logout", "logout", isRed: true),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label, String route, {bool isRed = false}) {
    bool isActive = activeRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () async {
          // 1. Close the drawer first
          Navigator.pop(context); 
          
          // 2. If we are already on this page, do nothing
          if (isActive) return;

          // 3. LOGIC: Handle specific page navigation with Data (child object)
          switch (route) {
            case "overview":
              Navigator.pushReplacementNamed(context, '/parent_dashboard');
              break;
              
            case "reports":
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => ChildInsightsScreen(child: child))
              );
              break;

            case "limits":
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => ScreenTimeSettingsScreen(child: child))
              );
              break;

            case "switch":
              Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
              break;

            case "add":
              Navigator.pushNamed(context, '/add_child');
              break;

            case "logout":
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false);
              break;
              
            default:
              debugPrint("Coming soon: $route");
          }
        },
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: isActive ? AppColors.ultraViolet.withOpacity(0.1) : Colors.transparent,
        leading: Icon(icon, color: isRed ? Colors.red : (isActive ? AppColors.ultraViolet : Colors.grey.shade600)),
        title: Text(label, style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isRed ? Colors.red : (isActive ? AppColors.ultraViolet : Colors.black87)
        )),
        trailing: isActive ? Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.ultraViolet, borderRadius: BorderRadius.circular(10))) : null,
      ),
    );
  }
}