import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/admin_scaffold.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);

    return AdminScaffold(
      title: "Global Settings",
      breadcrumbs: const ["Home", "Settings"],
      body: ListView(
        padding: const EdgeInsets.all(25),
        children: [
          _section(theme, "APP BRANDING"),
          _buildTextField(theme, "Application Name", "LittleGenius"),
          _buildTextField(theme, "Admin Email Support", "admin@littlegenius.com"),
          
          const SizedBox(height: 30),
          _section(theme, "SECURITY & ACCESS"),
          _buildToggle(theme, "Maintenance Mode", false),
          _buildToggle(theme, "Two-Factor Authentication", true),
          
          const SizedBox(height: 30),
          _section(theme, "DATABASE OPERATIONS"),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanBlue, minimumSize: const Size(0, 50)),
            onPressed: () {}, 
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: const Text("Download Database Backup (.json)", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeService theme, String title) {
    return Text(title, style: TextStyle(color: theme.subTextColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2));
  }

  Widget _buildTextField(ThemeService theme, String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        initialValue: initialValue,
        style: TextStyle(color: theme.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.subTextColor),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildToggle(ThemeService theme, String label, bool val) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: theme.textColor)),
      trailing: Switch(value: val, activeColor: AppColors.teal, onChanged: (v) {}),
    );
  }
}