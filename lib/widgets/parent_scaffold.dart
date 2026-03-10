import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/child_model.dart';
import '../utils/app_colors.dart';
import '../services/database_service.dart';
import '../screens/parent/child_insights_screen.dart'; 
import '../screens/parent/screen_time_settings.dart'; 
import '../screens/parent/notification_history_screen.dart'; 

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
    final user = FirebaseAuth.instance.currentUser;
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBEE),
      drawer: _buildSidebar(context),
      appBar: AppBar(
        title: Text(title.toUpperCase(), 
            style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ultraViolet,
        elevation: 0,
        centerTitle: true,
        actions: [
          // --- BRANDED LOGO NOTIFICATION BUTTON ---
          if (user != null) StreamBuilder<int>(
            stream: db.streamUnreadCount(user.uid),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;
              return _buildLogoButton(context, unreadCount > 0);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: body,
    );
  }

  Widget _buildLogoButton(BuildContext context, bool hasUnread) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationHistoryScreen()));
      },
      child: Center(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // THE APP LOGO (Clean, No extra BG)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.jpg', 
                  width: 36, height: 36, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.notifications, color: AppColors.ultraViolet),
                ),
              ),
            ),
            // SMART RED DOT (Only shows if there are unread items)
            if (hasUnread)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.ultraViolet),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, backgroundImage: AssetImage(child.avatarUrl)),
            accountName: Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("Class: ${child.childClass}", style: const TextStyle(color: Colors.white70)),
          ),
          _sidebarItem(context, Icons.dashboard_rounded, "Overview", "overview"),
          _sidebarItem(context, Icons.analytics_rounded, "Learning Reports", "reports"),
          _sidebarItem(context, Icons.timer_rounded, "Time Limits", "limits"),
          const Divider(),
          _sidebarItem(context, Icons.swap_horizontal_circle_rounded, "Switch Profile", "switch"),
          _sidebarItem(context, Icons.person_add_alt_1_rounded, "Add New Child", "add"),
          const Spacer(),
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
          Navigator.pop(context); 
          if (isActive) return;
          switch (route) {
            case "overview": Navigator.pushReplacementNamed(context, '/parent_dashboard'); break;
            case "reports": Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ChildInsightsScreen(child: child))); break;
            case "limits": Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ScreenTimeSettingsScreen(child: child))); break;
            case "switch": Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false); break;
            case "add": Navigator.pushNamed(context, '/add_child'); break;
            case "logout": await FirebaseAuth.instance.signOut(); Navigator.pushNamedAndRemoveUntil(context, '/landing', (r) => false); break;
          }
        },
        dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: isActive ? AppColors.ultraViolet.withValues(alpha: 0.1) : Colors.transparent,
        leading: Icon(icon, color: isRed ? Colors.red : (isActive ? AppColors.ultraViolet : Colors.grey.shade600)),
        title: Text(label, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isRed ? Colors.red : (isActive ? AppColors.ultraViolet : Colors.black87))),
        trailing: isActive ? Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.ultraViolet, borderRadius: BorderRadius.circular(10))) : null,
      ),
    );
  }
}