import 'package:flutter/material.dart';
import 'package:project/models/notification_model.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _nextId = 1;

  List<NotificationModel> get notifications => _notifications;

  // Get unread notifications count
  int get unreadCount => _notifications.where((notification) => !notification.isRead).length;

  // Initialize the provider
  Future<void> initialize() async {
    try {
      // First load local notifications
      await _loadNotifications();

      // Then try to fetch from API (if available)
      try {
        final apiNotifications = await NotificationService.fetchNotifications();

        // Merge with local notifications
        for (var notification in apiNotifications) {
          final existingIndex = _notifications.indexWhere((n) =>
            n.type == notification.type &&
            n.sourceId == notification.sourceId
          );

          if (existingIndex != -1) {
            // Update existing notification
            _notifications[existingIndex] = notification;
          } else {
            // Add new notification
            _notifications.add(notification);
          }
        }

        // Save to local storage
        await _saveNotifications();
      } catch (e) {
        print('Failed to fetch notifications from API: $e');
        // Continue with local notifications
      }

      // Sort notifications
      _sortNotifications();

      // Notify listeners
      notifyListeners();
    } catch (e) {
      print('Error initializing notification provider: $e');
      // Initialize with empty list if everything fails
      _notifications = [];
    }
  }

  // Add a goal reminder notification
  Future<void> addGoalReminderNotification(Goal goal) async {
    if (!(goal.hasReminder ?? false) || goal.reminderDateTime == null) {
      return;
    }

    // Ensure we're using the exact same DateTime object from the goal
    // This preserves the original time that was set by the user
    final reminderDateTime = goal.reminderDateTime;

    // Debug print to check the actual reminder time
    final now = DateTime.now();

    print('NOTIFICATION PROVIDER - Adding reminder notification for goal: ${goal.title}');
    print('NOTIFICATION PROVIDER - Reminder date/time: ${reminderDateTime.toString()}');

    // Check if the reminder time is in UTC (has 'Z' suffix)
    bool isUtc = reminderDateTime!.toString().endsWith('Z');
    print('NOTIFICATION PROVIDER - Is UTC time: $isUtc');

    print('NOTIFICATION PROVIDER - Reminder time (24-hour): ${reminderDateTime.hour}:${reminderDateTime.minute}');
    print('NOTIFICATION PROVIDER - Reminder time (12-hour): ${formatTo12Hour(reminderDateTime.hour, reminderDateTime.minute)}');
    print('NOTIFICATION PROVIDER - Current time: ${now.toString()}');
    print('NOTIFICATION PROVIDER - Current time (12-hour): ${formatTo12Hour(now.hour, now.minute)}');

    // If the time is in UTC, convert it to local time for comparison
    DateTime localReminderDateTime = reminderDateTime;
    if (isUtc) {
      // Convert UTC time to local time
      localReminderDateTime = reminderDateTime.toLocal();
      print('NOTIFICATION PROVIDER - Reminder date time (converted to local): ${localReminderDateTime.toString()}');
      print('NOTIFICATION PROVIDER - Reminder time after conversion (24-hour): ${localReminderDateTime.hour}:${localReminderDateTime.minute}');
      print('NOTIFICATION PROVIDER - Reminder time after conversion (12-hour): ${formatTo12Hour(localReminderDateTime.hour, localReminderDateTime.minute)}');
    }

    print('NOTIFICATION PROVIDER - Time difference in minutes: ${localReminderDateTime.difference(now).inMinutes}');

    // Check if a notification for this goal already exists
    final existingIndex = _notifications.indexWhere(
      (notification) =>
        notification.type == NotificationType.goalReminder &&
        notification.sourceId == goal.id
    );

    if (existingIndex != -1) {
      // Update existing notification
      _notifications[existingIndex] = _notifications[existingIndex].copyWith(
        title: 'Goal Reminder: ${goal.title}',
        message: 'Reminder for your goal: ${goal.title}',
        dueDateTime: reminderDateTime,
        isRead: false,
      );
    } else {
      // Create new notification
      final notification = NotificationModel(
        id: _nextId++,
        title: 'Goal Reminder: ${goal.title}',
        message: 'Reminder for your goal: ${goal.title}',
        createdAt: DateTime.now(),
        dueDateTime: reminderDateTime,
        type: NotificationType.goalReminder,
        sourceId: goal.id,
      );
      _notifications.add(notification);
    }

    // Sort notifications
    _sortNotifications();

    await _saveNotifications();
    notifyListeners();

    // The backend will automatically create/update the notification when the goal is saved
    // No need to make an additional API call here
  }

  // Remove a goal reminder notification
  Future<void> removeGoalReminderNotification(int goalId) async {
    _notifications.removeWhere(
      (notification) =>
        notification.type == NotificationType.goalReminder &&
        notification.sourceId == goalId
    );
    await _saveNotifications();
    notifyListeners();

    // The backend will automatically remove the notification when the goal is updated/deleted
    // No need to make an additional API call here
  }

  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();

      // Update on the server
      try {
        await NotificationService.markAsRead(notificationId);
      } catch (e) {
        print('Failed to mark notification as read on server: $e');
        // Continue with local update
      }
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((notification) => notification.copyWith(isRead: true)).toList();
    await _saveNotifications();
    notifyListeners();

    // Update on the server
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      print('Failed to mark all notifications as read on server: $e');
      // Continue with local update
    }
  }

  // Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    _notifications.removeWhere((notification) => notification.id == notificationId);
    await _saveNotifications();
    notifyListeners();

    // Delete on the server
    try {
      await NotificationService.deleteNotification(notificationId);
    } catch (e) {
      print('Failed to delete notification on server: $e');
      // Continue with local deletion
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();

    // Delete on the server
    try {
      await NotificationService.deleteAllNotifications();
    } catch (e) {
      print('Failed to delete all notifications on server: $e');
      // Continue with local deletion
    }
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications.map((notification) => {
      'id': notification.id,
      'title': notification.title,
      'message': notification.message,
      'createdAt': notification.createdAt.toIso8601String(),
      'dueDateTime': notification.dueDateTime?.toIso8601String(),
      'type': notification.type.index,
      'sourceId': notification.sourceId,
      'isRead': notification.isRead,
    }).toList();

    await prefs.setString('notifications', jsonEncode(notificationsJson));
    await prefs.setInt('next_notification_id', _nextId);
  }

  // Sort notifications by due date and creation time
  void _sortNotifications() {
    _notifications.sort((a, b) {
      // First, sort by read status (unread first)
      if (!a.isRead && b.isRead) return -1;
      if (a.isRead && !b.isRead) return 1;

      // Then sort by due date
      if (a.dueDateTime != null && b.dueDateTime != null) {
        // If both have due dates, sort by due date (upcoming first)
        return a.dueDateTime!.compareTo(b.dueDateTime!);
      } else if (a.dueDateTime != null) {
        // a has due date, b doesn't - a comes first
        return -1;
      } else if (b.dueDateTime != null) {
        // b has due date, a doesn't - b comes first
        return 1;
      }

      // If neither has due date, sort by creation time (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null && notificationsJson.isNotEmpty) {
        final List<dynamic> decodedJson = jsonDecode(notificationsJson);

        _notifications = [];
        for (var item in decodedJson) {
          try {
            // Safely extract values with null checks
            final id = item['id'] as int? ?? 0;
            final title = item['title'] as String? ?? 'Notification';
            final message = item['message'] as String? ?? '';
            final createdAtStr = item['createdAt'] as String?;
            final dueDateTimeStr = item['dueDateTime'] as String?;
            final typeIndex = item['type'] as int? ?? 0;
            final sourceId = item['sourceId'] as int?;
            final isRead = item['isRead'] as bool? ?? false;

            // Parse dates safely
            DateTime createdAt;
            try {
              createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
            } catch (e) {
              createdAt = DateTime.now();
            }

            DateTime? dueDateTime;
            if (dueDateTimeStr != null) {
              try {
                dueDateTime = DateTime.parse(dueDateTimeStr);
              } catch (e) {
                dueDateTime = null;
              }
            }

            // Create notification with safe values
            final notification = NotificationModel(
              id: id,
              title: title,
              message: message,
              createdAt: createdAt,
              dueDateTime: dueDateTime,
              type: NotificationType.values[typeIndex.clamp(0, NotificationType.values.length - 1)],
              sourceId: sourceId,
              isRead: isRead,
            );

            _notifications.add(notification);
          } catch (e) {
            print('Error parsing notification: $e');
            // Skip this notification
          }
        }

        _nextId = prefs.getInt('next_notification_id') ?? 1;
      }
    } catch (e) {
      print('Error loading notifications: $e');
      // Initialize with empty list
      _notifications = [];
    }
  }
}
