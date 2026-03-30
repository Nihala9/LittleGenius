import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  // Function to delete all logs for this parent
  Future<void> _clearAllNotifications(String uid) async {
    var collection = FirebaseFirestore.instance
        .collection('parents')
        .doc(uid)
        .collection('notifications');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBEE),
      appBar: AppBar(
        title: const Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ultraViolet,
        elevation: 0,
        actions: [
          // --- NEW: Clear All Button ---
          TextButton(
            onPressed: () => _clearAllNotifications(uid!),
            child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 10),
                  const Text("No recent alerts.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final data = logs[index].data() as Map<String, dynamic>;
              DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: AppColors.ultraViolet.withValues(alpha: 0.05))
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data['type'] == 'struggle' 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : AppColors.lemonChiffon,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      data['type'] == 'struggle' ? Icons.lightbulb_outline_rounded : Icons.access_time_rounded, 
                      color: data['type'] == 'struggle' ? Colors.orange : AppColors.ultraViolet, 
                      size: 20
                    ),
                  ),
                  title: Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(data['body'], style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    DateFormat('h:mm a').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}