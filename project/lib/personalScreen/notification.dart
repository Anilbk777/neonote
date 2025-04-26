import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/notification_model.dart';
import 'package:project/services/local_storage.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/goal.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // Initialize notifications when the page is opened
    _refreshNotifications();
  }

  // Refresh notifications
  Future<void> _refreshNotifications() async {
    if (_isLoading) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user info for debugging
      final userData = await LocalStorage.getUser();
      if (userData != null) {
        print('🧑‍💻 Current user: ${userData['email']} (ID: ${userData['id']})');
      } else {
        print('⚠️ No user data found in local storage');
        setState(() {
          _errorMessage = 'You need to be logged in to view notifications.';
        });
        return;
      }

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.initialize();
      print('✅ Notifications refreshed successfully');
    } catch (error) {
      print('❌ Error refreshing notifications: $error');
      setState(() {
        _errorMessage = 'Failed to load notifications. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Notification',
      onItemSelected: (page) {},
      body: Container(
        color: Colors.white,
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final notifications = notificationProvider.notifications;

            // Show full-screen loading indicator while fetching notifications
            if (_isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Color(0xFF255DE1),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Loading notifications...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF255DE1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show empty state or error message when no notifications
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _errorMessage.isNotEmpty ? Icons.error_outline : Icons.notifications_off,
                      size: 64,
                      color: _errorMessage.isNotEmpty ? Colors.red.shade300 : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage.isNotEmpty ? _errorMessage : 'No notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: _errorMessage.isNotEmpty ? Colors.red.shade300 : Colors.grey,
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _refreshNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF255DE1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF255DE1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _isLoading ? null : _refreshNotifications,
                            tooltip: 'Refresh notifications',
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            onPressed: notifications.isEmpty || _isLoading
                                ? null
                                : () {
                                    notificationProvider.markAllAsRead();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('All notifications marked as read'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            tooltip: 'Mark all as read',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: notifications.isEmpty || _isLoading
                                ? null
                                : () {
                                    _showDeleteAllConfirmationDialog(context);
                                  },
                            tooltip: 'Delete all notifications',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(context, notification);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notification) {
    final now = DateTime.now();
    bool isPast = false;

    if (notification.dueDateTime != null) {
      // Get the due date time
      DateTime dueDateTime = notification.dueDateTime!;

      // Debug prints to help diagnose time issues
      print('NOTIFICATION CARD - Original time: ${dueDateTime.toString()}');
      print('NOTIFICATION CARD - Due time (24-hour): ${dueDateTime.hour}:${dueDateTime.minute}');
      print('NOTIFICATION CARD - Due time (12-hour): ${formatTo12Hour(dueDateTime.hour, dueDateTime.minute)}');
      print('NOTIFICATION CARD - Current time (24-hour): ${now.hour}:${now.minute}');
      print('NOTIFICATION CARD - Current time (12-hour): ${formatTo12Hour(now.hour, now.minute)}');

      // Simple check if the due time is in the past
      isPast = (dueDateTime.year < now.year) ||
               (dueDateTime.year == now.year && dueDateTime.month < now.month) ||
               (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day < now.day) ||
               (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day == now.day &&
                dueDateTime.hour < now.hour) ||
               (dueDateTime.year == now.year && dueDateTime.month == now.month && dueDateTime.day == now.day &&
                dueDateTime.hour == now.hour && dueDateTime.minute < now.minute);

      // Get the remaining time from the notification model
      final remainingTime = notification.remainingTime;
      print('NOTIFICATION CARD - Remaining time: $remainingTime');
    }

    return Dismissible(
      key: Key('notification-${notification.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(context, listen: false)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification.isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: notification.isRead
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF255DE1), width: 1),
        ),
        child: InkWell(
          onTap: () {
            _handleNotificationTap(context, notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getNotificationIcon(notification, isPast),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (notification.dueDateTime != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isPast ? Colors.red : Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.formattedDueDateTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPast ? Colors.red : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (!isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  notification.remainingTime,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            if (isPast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  "Overdue",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF255DE1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationModel notification, bool isPast) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.goalReminder:
        iconData = Icons.flag;
        iconColor = isPast ? Colors.red : const Color(0xFF255DE1);
        break;
      case NotificationType.taskDue:
        iconData = Icons.task_alt;
        iconColor = isPast ? Colors.red : Colors.orange;
        break;
      case NotificationType.systemNotification:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    Provider.of<NotificationProvider>(context, listen: false)
        .markAsRead(notification.id);

    if (notification.type == NotificationType.goalReminder && notification.sourceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GoalPage()),
      );
    }
  }

  void _showDeleteAllConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .deleteAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
