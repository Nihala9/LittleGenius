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

  // --- 3. STRUGGLE ALERT (WITH OFFLINE ADVICE) ---
  Future<void> notifyStruggle(String childName, String conceptName, String category) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Map Category to the specific Offline Task
    Map<String, String> adviceMap = {
      'Alphabets': 'Try drawing letters with your child in a tray of sand.',
      'Numbers': 'Ask your child to help you count 5 spoons at home.',
      'Animals': 'Ask your child to make the sound of their favorite animal.',
      'Shapes': 'Look for circular objects together in the room.',
      'General': 'Read a picture book together before bedtime.',
    };

    String task = adviceMap[category] ?? adviceMap['General']!;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'struggle_channel',
      'Learning Support',
      channelDescription: 'Alerts when your child needs extra help',
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: Colors.orangeAccent,
      styleInformation: BigTextStyleInformation(
        '**$childName is struggling with $conceptName.**\n\n💡 Try this offline: $task',
        htmlFormatContent: true,
        htmlFormatTitle: true,
      ),
    );

    await _notificationsPlugin.show(
      notificationId,
      "Help $childName learn! 💡",
      "$childName is struggling with $conceptName. Tap for advice.",
      NotificationDetails(android: androidDetails),
    );
  }
}