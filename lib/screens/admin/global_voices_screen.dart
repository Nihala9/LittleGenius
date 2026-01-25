import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';

class GlobalVoicesScreen extends StatelessWidget {
  const GlobalVoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    final List<Map<String, String>> langAssets = [
      {'lang': 'Malayalam', 'engine': 'Google TTS-ml', 'status': 'Active'},
      {'lang': 'Hindi', 'engine': 'Google TTS-hi', 'status': 'Active'},
      {'lang': 'Spanish', 'engine': 'Apple-es-MX', 'status': 'Active'},
      {'lang': 'French', 'engine': 'Google-fr-FR', 'status': 'Beta'},
    ];

    return Scaffold(
      backgroundColor: theme.bgColor,
      appBar: AppBar(
        title: Text("GLOBAL VOICE ASSETS", 
          style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: langAssets.length,
        itemBuilder: (context, i) => Card(
          color: theme.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: theme.borderColor),
          ),
          child: ListTile(
            leading: const Icon(Icons.record_voice_over, color: AppColors.teal),
            title: Text(langAssets[i]['lang']!, 
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
            subtitle: Text(langAssets[i]['engine']!, 
              style: TextStyle(color: theme.subTextColor)),
            trailing: Chip(
              label: Text(langAssets[i]['status']!, style: const TextStyle(fontSize: 10, color: Colors.white)), 
              backgroundColor: AppColors.teal,
            ),
          ),
        ),
      ),
    );
  }
}