import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/models/notification_model.dart';
import 'package:project/services/local_storage.dart';

class NotificationService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/notifications';

  // Get headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch all notifications for the current user
  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Fetching notifications...');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('✅ Successfully fetched ${data.length} notifications');
        
        return data.map((json) => _convertToNotificationModel(json)).toList();
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      throw Exception('Failed to load notifications: $e');
    }
  }

  // Mark a notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Marking notification #$notificationId as read');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/mark_as_read/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ Notification marked as read');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Marking all notifications as read');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark_all_as_read/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ All notifications marked as read');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Deleting notification #$notificationId');

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        print('✅ Notification deleted');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting notification: $e');
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      print('📡 Deleting all notifications');

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/delete_all/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        print('✅ All notifications deleted');
        return;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        throw Exception('Failed to delete all notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Convert API response to NotificationModel
  static NotificationModel _convertToNotificationModel(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['notification_type']) {
      case 'goal_reminder':
        type = NotificationType.goalReminder;
        break;
      case 'task_due':
        type = NotificationType.taskDue;
        break;
      default:
        type = NotificationType.systemNotification;
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      dueDateTime: json['due_date_time'] != null ? DateTime.parse(json['due_date_time']) : null,
      type: type,
      sourceId: json['source_id'],
      isRead: json['is_read'],
    );
  }
}
