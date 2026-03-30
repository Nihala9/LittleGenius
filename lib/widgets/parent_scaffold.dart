import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for the professional Delete Dialog
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

  // --- DELETE LOGIC ---
  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Delete Profile?"),
        content: Text("Are you sure you want to delete ${child.name}'s profile? All progress and stars will be permanently lost."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Call the delete method from your DatabaseService
                await DatabaseService().deleteChildProfile(user.uid, child.id);
                
                // Close dialog and go back to profile selection
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/profile_selector', (r) => false);
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- HELP CENTER LOGIC ---
  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Parent Help Center", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ultraViolet)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _helpItem("How to set screen time?", "Navigate to 'Time Limits' in the menu. You can slide the timer to set daily minutes for each child."),
                  _helpItem("What are Mastery Scores?", "They represent your child's understanding of a topic. 80% or higher means they have mastered the concept!"),
                  _helpItem("Can I add another child?", "Yes! Click 'Add New Child' in the sidebar to create a separate learning path for a sibling."),
                  _helpItem("App is locking too early?", "Check if the 'Daily Limit' has been reached. You can increase it anytime in Time settings."),
                  const SizedBox(height: 20),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.ultraViolet),
                    title: const Text("Email Support"),
                    subtitle: const Text("littlegenius@kidapp.com"),
                    onTap: () { /* Link to mailto: */ },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          child: Text(answer, style: const TextStyle(color: Colors.black54, height: 1.4)),
        )
      ],
    );
  }

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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationHistoryScreen())),
      child: Center(
        child: Stack(
          alignment: Alignment.topRight,
          children: [
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
            if (hasUnread)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
          _sidebarItem(context, Icons.delete_outline_rounded, "Delete Profile", "delete", isRed: true),
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
          if (route == "delete") {
            _showDeleteConfirmation(context);
            return;
          }
          if (route == "help") {
            Navigator.pop(context); // Close drawer
            _showHelpCenter(context);
            return;
          }

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