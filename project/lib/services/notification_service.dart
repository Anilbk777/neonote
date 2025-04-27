import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/models/notification_model.dart';
import 'package:project/services/local_storage.dart';

class NotificationService {
  // Base URL for the API
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Notifications endpoint - note the double 'notifications' in the path
  // This matches the Django router structure
  static const String notificationsEndpoint = '/notifications/notifications';

  // Print the full URL for debugging
  static void _logUrl(String endpoint) {
    print('🔗 API URL: $baseUrl$notificationsEndpoint$endpoint');
  }

  // Get headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    print('🔑 Using authentication token: ${token.substring(0, 10)}...');

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch all notifications for the current user
  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final headers = await _getAuthHeaders();
      // Use the correct endpoint for fetching notifications
      // The endpoint should be empty since we're already at the notifications base URL
      final endpoint = '';
      _logUrl(endpoint);
      print('📡 Fetching notifications...');

      // Get user info for debugging
      final userData = await LocalStorage.getUser();
      if (userData != null) {
        print('🧑‍💻 Fetching notifications for user: ${userData['email']}');
      } else {
        print('⚠️ No user data found when fetching notifications');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$notificationsEndpoint$endpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('✅ Response status code: 200');

        // Print raw response for debugging
        print('📄 Raw API response:');
        print(response.body);

        // Parse the response
        final dynamic decodedData = json.decode(response.body);
        List<dynamic> data = [];

        // Handle different response formats
        if (decodedData is List) {
          // If the response is already a list, use it directly
          data = decodedData;
          print('✅ API returned a list with ${data.length} notifications');
        } else if (decodedData is Map) {
          // If the response is a map, check if it contains a results field or similar
          print('⚠️ API returned a map instead of a list');

          if (decodedData.containsKey('results')) {
            // Some APIs wrap the results in a 'results' field
            data = decodedData['results'] as List;
            print('✅ Found ${data.length} notifications in the results field');
          } else if (decodedData.containsKey('notifications')) {
            // Some APIs wrap the results in a 'notifications' field
            final notificationsValue = decodedData['notifications'];

            // Check if the notifications value is a URL string
            if (notificationsValue is String && notificationsValue.startsWith('http')) {
              print('🔗 Found notifications URL: $notificationsValue');

              // Make a follow-up request to the URL
              try {
                print('🔄 Making follow-up request to notifications URL');
                final followUpResponse = await http.get(
                  Uri.parse(notificationsValue),
                  headers: headers,
                );

                if (followUpResponse.statusCode == 200) {
                  print('✅ Follow-up request successful');
                  print('📄 Follow-up response:');
                  print(followUpResponse.body);

                  final followUpData = json.decode(followUpResponse.body);
                  if (followUpData is List) {
                    data = followUpData;
                    print('✅ Found ${data.length} notifications in follow-up response');
                  } else if (followUpData is Map && followUpData.containsKey('results')) {
                    data = followUpData['results'] as List;
                    print('✅ Found ${data.length} notifications in follow-up response results field');
                  } else {
                    print('⚠️ Follow-up response is not a list or does not contain results');
                    data = [];
                  }
                } else {
                  print('❌ Follow-up request failed: ${followUpResponse.statusCode}');
                  print('❌ Follow-up response body: ${followUpResponse.body}');
                  data = [];
                }
              } catch (e) {
                print('❌ Error making follow-up request: $e');
                data = [];
              }
            } else if (notificationsValue is List) {
              // If notifications is already a list, use it directly
              data = notificationsValue;
              print('✅ Found ${data.length} notifications in the notifications field');
            } else {
              print('⚠️ Notifications field is not a list or URL: ${notificationsValue.runtimeType}');
              data = [];
            }
          } else {
            // If we can't find a list of notifications, create a list with just this object
            // This is for APIs that return a single notification as an object
            print('⚠️ No list found in response, treating as a single notification');

            // Print all keys in the response for debugging
            print('📊 Keys in response: ${decodedData.keys.join(', ')}');

            // Create a list of notifications from the map data
            // First check if this looks like a notification object
            if (decodedData.containsKey('id') ||
                decodedData.containsKey('title') ||
                decodedData.containsKey('message')) {
              data = [decodedData];
              print('✅ Created a list with 1 notification from the response object');
            } else {
              // If it doesn't look like a notification, return an empty list
              print('⚠️ Response does not contain notification data, returning empty list');
              return [];
            }
          }
        } else {
          // If the response is neither a list nor a map, return an empty list
          print('⚠️ Unexpected response format: ${decodedData.runtimeType}');
          return [];
        }

        print('✅ Successfully processed ${data.length} notifications from API');

        // Convert to notification models
        final notifications = data.map((item) => _convertToNotificationModel(item)).toList();

        // Print detailed notification information
        print('📊 Notification details:');
        if (notifications.isEmpty) {
          print('   No notifications found for this user');
        } else {
          for (var notification in notifications) {
            print('   - ID: ${notification.id}');
            print('     Title: ${notification.title}');
            print('     Message: ${notification.message}');
            print('     Type: ${notification.type}');
            print('     Created: ${notification.createdAt}');
            print('     Due: ${notification.dueDateTime}');
            print('     Source ID: ${notification.sourceId}');
            print('     Read: ${notification.isRead}');
            print('     ---');
          }
        }

        return notifications;
      } else if (response.statusCode == 401) {
        print('🔒 Authentication failed. Token might be expired.');
        print('🔒 Response body: ${response.body}');
        await LocalStorage.clearToken();
        throw Exception('Your session has expired. Please login again.');
      } else {
        print('❌ Failed to load notifications: ${response.statusCode}');
        print('❌ Response body: ${response.body}');

        // Try to parse the error message from the response
        String errorMessage = 'Failed to load notifications: ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = 'Error: ${errorData['detail']}';
          }
        } catch (e) {
          // If we can't parse the error, just use the default message
        }

        throw Exception(errorMessage);
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

      // Use the correct endpoint format as defined in the Django ViewSet
      final endpoint = '/$notificationId/mark_as_read/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      // Add extra debugging
      print('🔍 Notification ID: $notificationId');
      print('🔍 Headers: $headers');

      final response = await http.post(
        Uri.parse(url),
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

      final endpoint = '/mark_all_as_read/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.post(
        Uri.parse(url),
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

      final endpoint = '/$notificationId/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.delete(
        Uri.parse(url),
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

      final endpoint = '/delete_all/';
      _logUrl(endpoint);

      // Print the full URL for debugging
      final url = '$baseUrl$notificationsEndpoint$endpoint';
      print('🔗 Full URL: $url');

      final response = await http.delete(
        Uri.parse(url),
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
    print('🔄 Converting notification JSON: $json');

    // Parse dates safely
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'] ?? json['createdAt'];
      if (createdAtStr != null) {
        createdAt = DateTime.parse(createdAtStr.toString());
        print('✅ Parsed createdAt: $createdAt');
      } else {
        print('⚠️ No createdAt found, using current time');
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('❌ Error parsing createdAt: $e');
      createdAt = DateTime.now();
    }

    DateTime? dueDateTime;
    try {
      final dueDateTimeStr = json['due_date_time'] ?? json['dueDateTime'];
      if (dueDateTimeStr != null) {
        dueDateTime = DateTime.parse(dueDateTimeStr.toString());
        print('✅ Parsed dueDateTime: $dueDateTime');
      }
    } catch (e) {
      print('❌ Error parsing dueDateTime: $e');
      dueDateTime = null;
    }

    // Determine notification type
    NotificationType type;
    try {
      final notificationType = json['notification_type'] ?? json['type'];

      if (notificationType is int) {
        final typeIndex = notificationType;
        if (typeIndex >= 0 && typeIndex < NotificationType.values.length) {
          type = NotificationType.values[typeIndex];
          print('✅ Using type from index: $type');
        } else {
          print('⚠️ Type index out of range: $typeIndex');
          type = NotificationType.systemNotification;
        }
      } else if (notificationType is String) {
        final typeStr = notificationType;
        switch (typeStr) {
          case 'goal_reminder':
            type = NotificationType.goalReminder;
            break;
          case 'task_due':
            type = NotificationType.taskDue;
            break;
          default:
            try {
              type = NotificationType.values.firstWhere(
                (e) => e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
                orElse: () {
                  print('⚠️ Type string not found: $typeStr');
                  return NotificationType.systemNotification;
                },
              );
            } catch (e) {
              print('❌ Error parsing type string: $e');
              type = NotificationType.systemNotification;
            }
        }
        print('✅ Using type from string: $type');
      } else {
        print('⚠️ No valid type found, using default');
        type = NotificationType.systemNotification;
      }
    } catch (e) {
      print('❌ Error determining notification type: $e');
      type = NotificationType.systemNotification;
    }

    // Get ID safely
    int id;
    try {
      if (json['id'] is int) {
        id = json['id'];
      } else if (json['id'] is String) {
        id = int.parse(json['id']);
      } else {
        id = 0;
      }
    } catch (e) {
      print('❌ Error parsing ID: $e');
      id = 0;
    }

    // Get source ID safely
    int? sourceId;
    try {
      final rawSourceId = json['source_id'] ?? json['sourceId'];
      if (rawSourceId is int) {
        sourceId = rawSourceId;
      } else if (rawSourceId is String) {
        sourceId = int.parse(rawSourceId);
      }
    } catch (e) {
      print('❌ Error parsing sourceId: $e');
      sourceId = null;
    }

    // Get isRead safely
    bool isRead;
    try {
      final rawIsRead = json['is_read'] ?? json['isRead'] ?? false;
      if (rawIsRead is bool) {
        isRead = rawIsRead;
      } else if (rawIsRead is String) {
        isRead = rawIsRead.toLowerCase() == 'true';
      } else if (rawIsRead is int) {
        isRead = rawIsRead != 0;
      } else {
        isRead = false;
      }
    } catch (e) {
      print('❌ Error parsing isRead: $e');
      isRead = false;
    }

    // Create and return the notification model
    final notification = NotificationModel(
      id: id,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      createdAt: createdAt,
      dueDateTime: dueDateTime,
      type: type,
      sourceId: sourceId,
      isRead: isRead,
    );

    print('✅ Successfully converted notification: ${notification.id} - ${notification.title}');
    return notification;
  }
}
