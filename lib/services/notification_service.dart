import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // --- FIX FOR REDMI NOTE 14 ---
    // We use the 'ic_stat_name' (white silhouette) for the status bar.
    // If you haven't created it yet, use 'app_icon' as a placeholder.
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('ic_stat_name'); 

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // --- 1. PROGRESS ALERT ---
  Future<void> notifyProgress(String childName, String category, int stars) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'progress_channel',
      'Learning Progress',
      importance: Importance.max,
      priority: Priority.high,
      // --- SHOW FULL COLOR LOGO HERE ---
      // This is what will show the colorful logo on the right side of the alert
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // This color only tints the small white icon
      color: const Color(0xFF5F4A8B), 
    );

    await _notificationsPlugin.show(
      notificationId,
      "Progress Update",
      "$childName earned $stars stars in $category! 🌟",
      NotificationDetails(android: androidDetails),
    );
  }

  // --- 2. USAGE ALERT ---
  Future<void> notifyUsageLimit(String childName, int minutesUsed, int limit) async {
    const int usageId = 99; 
    String title = minutesUsed >= limit ? "Time's Up! 🛑" : "Usage Update ⏳";

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'usage_channel', 
      'Screen Time Monitor',
      importance: Importance.high,
      priority: Priority.high,
      // --- SHOW FULL COLOR LOGO HERE ---
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Colors.redAccent, 
      onlyAlertOnce: true,
    );

    await _notificationsPlugin.show(
      usageId,
      title,
      "$childName has used $minutesUsed out of $limit minutes.",
      NotificationDetails(android: androidDetails),
    );
  }
}