import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';

class AccountHelpScreen extends StatelessWidget {
  const AccountHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final db = DatabaseService();

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("PARENT USER DIRECTORY", 
          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.streamAllParents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.textColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No parent accounts registered.", style: TextStyle(color: theme.subTextColor))
            );
          }
          
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Card(
                color: theme.cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: theme.borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                    child: const Icon(Icons.person, color: AppColors.primaryBlue),
                  ),
                  title: Text(data['email'] ?? 'No Email', 
                    style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text("Parent ID: ${docs[i].id}", 
                    style: TextStyle(color: theme.subTextColor, fontSize: 10)),
                  trailing: Icon(Icons.mail_outline, color: theme.subTextColor),
                ),
              );
            },
          );
        },
      ),
    );
  }
}