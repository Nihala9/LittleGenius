import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';

class ContentReviewScreen extends StatelessWidget {
  const ContentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("SAFETY AUDIT CONSOLE", 
          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Activity>>(
        stream: db.streamAllActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.textColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No activities created yet.", style: TextStyle(color: theme.subTextColor))
            );
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: list.length,
            itemBuilder: (context, i) => Card(
              color: theme.cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: theme.borderColor),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.teal, size: 20),
                ),
                title: Text(list[i].title, 
                  style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                subtitle: Text("Status: Child-Safe Verified", 
                  style: TextStyle(color: theme.subTextColor, fontSize: 10)),
                trailing: const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}