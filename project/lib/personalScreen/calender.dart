import 'package:flutter/material.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:project/services/calendar_service.dart';
import 'package:project/services/local_storage.dart';
import 'dart:math';

// Define our own enum for view types
enum CalendarViewType {
  month,
  week,
  day
}

class Calenderpage extends StatefulWidget {
  const Calenderpage({super.key});

  @override
  State<Calenderpage> createState() => _CalenderpageState();
}

class _CalenderpageState extends State<Calenderpage> {
  final GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();
  final GlobalKey<WeekViewState> _weekViewKey = GlobalKey<WeekViewState>();
  final GlobalKey<DayViewState> _dayViewKey = GlobalKey<DayViewState>();

  EventController eventController = EventController();
  CalendarViewType _calendarView = CalendarViewType.month;
  DateTime _focusedDate = DateTime.now();

  final CalendarService _calendarService = CalendarService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loginAndLoadEvents();
  }

  Future<void> _loginAndLoadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have a token
      final token = await LocalStorage.getToken();

      if (token != null && token.isNotEmpty) {
        print('✅ Token found, loading events');
      } else {
        print('⚠️ No token found, events may not load properly');
      }

      // Load events using the existing token
      await _loadEvents();
    } catch (e) {
      _handleError(e, 'checking token');
      // Still try to load events
      await _loadEvents();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle network errors gracefully
  void _handleError(dynamic error, String operation) {
    print('Error $operation: $error');
    String message = 'Failed to $operation. Please try again later.';

    // Check for specific error types
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('network connection') ||
        error.toString().contains('semaphore timeout')) {
      message = 'Cannot connect to server. Please make sure the Django server is running.';
      print('Server connection error - Django server may not be running');
    } else if (error.toString().contains('401')) {
      message = 'Authentication error. Please log in again.';
    } else if (error.toString().contains('timeout')) {
      message = 'Request timed out. Please try again.';
      print('Using sample data due to timeout');
    }

    // Show error message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          backgroundColor: error.toString().contains('SocketException') ||
                          error.toString().contains('Connection refused') ?
                          Colors.red : Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load events for the current month and the next month for better UX
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      final currentMonthEvents = await _calendarService.getEventsForMonth(now.year, now.month);
      final nextMonthEvents = await _calendarService.getEventsForMonth(nextMonth.year, nextMonth.month);

      // Clear existing events and add the new ones
      eventController.removeWhere((_) => true); // Remove all events
      eventController.addAll([...currentMonthEvents, ...nextMonthEvents]);
    } catch (e) {
      _handleError(e, 'load events');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load events when changing month, week, or day
  Future<void> _loadEventsForFocusedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<CalendarEventData<Object?>> events = [];

      switch (_calendarView) {
        case CalendarViewType.month:
          // For month view, load the current month and adjacent months
          final currentMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
          final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
          final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);

          final currentEvents = await _calendarService.getEventsForMonth(currentMonth.year, currentMonth.month);
          final prevEvents = await _calendarService.getEventsForMonth(prevMonth.year, prevMonth.month);
          final nextEvents = await _calendarService.getEventsForMonth(nextMonth.year, nextMonth.month);

          events = [...prevEvents, ...currentEvents, ...nextEvents];
          break;

        case CalendarViewType.week:
          // For week view, get the start and end of the week
          final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          events = await _calendarService.getEventsForRange(weekStart, weekEnd);
          break;

        case CalendarViewType.day:
          // For day view, just get the events for that day
          events = await _calendarService.getEventsForDay(_focusedDate);
          break;
      }

      // Update the event controller
      eventController.removeWhere((_) => true); // Remove all events
      eventController.addAll(events);
    } catch (e) {
      _handleError(e, 'load events');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Calendar',
      onItemSelected: (String value) {},
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF255DE1),
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: const Color(0xFF255DE1),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF255DE1),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.today),
                          onPressed: () {
                            setState(() {
                              _focusedDate = DateTime.now();
                            });
                            _jumpToToday();
                          },
                          tooltip: 'Today',
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => _loadEventsForFocusedDate(),
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _previousPage(),
                          tooltip: 'Previous',
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _nextPage(),
                          tooltip: 'Next',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildViewToggleButton(CalendarViewType.month, 'Month'),
                    const SizedBox(width: 10),
                    _buildViewToggleButton(CalendarViewType.week, 'Week'),
                    const SizedBox(width: 10),
                    _buildViewToggleButton(CalendarViewType.day, 'Day'),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDateHeader(),
              ],
            ),
          ),
          Expanded(
            child: _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton(CalendarViewType view, String title) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _calendarView == view ? const Color(0xFF255DE1) : Colors.grey.shade200,
        foregroundColor: _calendarView == view ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {
        setState(() {
          _calendarView = view;
        });
      },
      child: Text(title),
    );
  }

  Widget _buildDateHeader() {
    String headerText = '';
    switch (_calendarView) {
      case CalendarViewType.month:
        headerText = DateFormat('MMMM yyyy').format(_focusedDate);
        break;
      case CalendarViewType.week:
        final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        headerText = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
        break;
      case CalendarViewType.day:
        headerText = DateFormat('EEEE, MMMM d, yyyy').format(_focusedDate);
        break;
    }

    return Text(
      headerText,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  void _jumpToToday() {
    switch (_calendarView) {
      case CalendarViewType.month:
        _monthViewKey.currentState?.jumpToMonth(DateTime.now());
        break;
      case CalendarViewType.week:
        _weekViewKey.currentState?.jumpToWeek(DateTime.now());
        break;
      case CalendarViewType.day:
        _dayViewKey.currentState?.jumpToDate(DateTime.now());
        break;
    }
  }

  void _previousPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        _monthViewKey.currentState?.previousPage();
        break;
      case CalendarViewType.week:
        _weekViewKey.currentState?.previousPage();
        break;
      case CalendarViewType.day:
        _dayViewKey.currentState?.previousPage();
        break;
    }
  }

  void _nextPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        _monthViewKey.currentState?.nextPage();
        break;
      case CalendarViewType.week:
        _weekViewKey.currentState?.nextPage();
        break;
      case CalendarViewType.day:
        _dayViewKey.currentState?.nextPage();
        break;
    }
  }

  Widget _buildCalendarView() {
    switch (_calendarView) {
      case CalendarViewType.month:
        return MonthView(
          key: _monthViewKey,
          controller: eventController,
          onEventTap: (event, date) {
            _showEventDetailsDialog(context, event, date);
          },
          onCellTap: (events, date) {
            if (events.isNotEmpty) {
              _showEventDetailsDialog(context, events, date);
            } else {
              // Create event on empty cell tap
              _showAddEventDialog(context, initialDate: date);
            }
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
            });
            _loadEventsForFocusedDate();
          },
          // Hide the header as we're using our custom header
          headerBuilder: (date) => const SizedBox.shrink(),
          cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
            // Custom cell builder for better styling
            return Container(
              margin: const EdgeInsets.all(1),
              padding: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue.withOpacity(0.1) : null,
                border: Border.all(color: isToday ? Colors.blue : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Date number
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isInMonth ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Event indicators
                  Expanded(
                    child: events.isNotEmpty
                        ? ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: events.length > 3 ? 3 : events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: event.color.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.title ?? '',
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  // More events indicator
                  if (events.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '+${events.length - 3} more',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      case CalendarViewType.week:
        return WeekView(
          key: _weekViewKey,
          controller: eventController,
          onEventTap: (event, date) {
            _showEventDetailsDialog(context, event, date);
          },
          onDateLongPress: (date) {
            _showAddEventDialog(context, initialDate: date);
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
            });
            _loadEventsForFocusedDate();
          },
          // Hide the header as we're using our custom header
          weekPageHeaderBuilder: (startDate, endDate) => const SizedBox.shrink(),
          eventTileBuilder: (date, events, boundary, startTime, endTime) {
            // Custom event tile for week view
            if (events.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: events[0].color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  events[0].title ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      case CalendarViewType.day:
        return DayView(
          key: _dayViewKey,
          controller: eventController,
          onEventTap: (event, date) {
            _showEventDetailsDialog(context, event, date);
          },
          onDateLongPress: (date) {
            _showAddEventDialog(context, initialDate: date);
          },
          onPageChange: (date, page) {
            setState(() {
              _focusedDate = date;
            });
            _loadEventsForFocusedDate();
          },
          // Hide the header as we're using our custom header
          dayTitleBuilder: (date) => const SizedBox.shrink(),
          eventTileBuilder: (date, events, boundary, startTime, endTime) {
            // Custom event tile for day view
            if (events.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: events[0].color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              height: 34.0, // Fixed height to prevent overflow
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        events[0].title ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (events[0].description?.isNotEmpty ?? false)
                      Flexible(
                        child: Text(
                          events[0].description ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper method to format TimeOfDay in 12-hour format with AM/PM
  String _formatTimeOfDay(TimeOfDay time) {
    // Convert 24-hour format to 12-hour format
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showEventDetailsDialog(BuildContext context, dynamic eventOrEvents, DateTime date) {
    // Convert to list if it's a single event
    List<CalendarEventData<Object?>> events;
    if (eventOrEvents is List<CalendarEventData<Object?>>) {
      events = eventOrEvents;
    } else if (eventOrEvents is CalendarEventData<Object?>) {
      events = [eventOrEvents];
    } else {
      // Fallback for unexpected types
      events = [];
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Events on ${DateFormat('MMM d, yyyy').format(date)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: double.infinity,
                      color: event.color,
                    ),
                    title: Text(event.title ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.description?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(event.description ?? ''),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${DateFormat('h:mm a').format(event.startTime ?? date)} - ${DateFormat('h:mm a').format(event.endTime ?? date)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF255DE1)),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the details dialog
                            _showEditEventDialog(context, event, date);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () {
                        try {
                          print('Attempting to delete event: ${event.title}');

                          // Get the event ID from the event data
                          Map<String, dynamic>? eventData;
                          String? eventId;

                          try {
                            eventData = event.event as Map<String, dynamic>?;
                            eventId = eventData?['eventId'];
                            print('Event data: $eventData');
                            print('Event ID: $eventId');
                          } catch (e) {
                            print('Error extracting event ID: $e');
                          }

                          if (eventId == null) {
                            print('Event ID is null, checking if this is a sample event');
                            // For sample events that might not have an ID
                            if (event.event is String) {
                              // Old format where event is just the title string
                              eventId = 'sample-${DateTime.now().millisecondsSinceEpoch}';
                              print('Created sample ID for string event: $eventId');
                            } else {
                              _handleError('Event ID not found', 'delete event');
                              return;
                            }
                          }

                          // Delete from backend first
                          print('Calling deleteEvent with ID: $eventId');
                          _calendarService.deleteEvent(eventId).then((success) {
                            print('Delete result: $success');
                            if (success) {
                              eventController.remove(event);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Event "${event.title}" deleted')),
                              );
                            } else {
                              _handleError('Server returned failure', 'delete event');
                            }
                          }).catchError((error) {
                            print('Error in deleteEvent callback: $error');
                            _handleError(error, 'delete event');
                          });
                        } catch (e) {
                          print('Exception in event deletion UI: $e');
                          print('Stack trace: ${StackTrace.current}');
                          _handleError(e, 'prepare for deletion');
                        }
                      },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF255DE1),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _showAddEventDialog(context, initialDate: date);
              },
              child: const Text('Add Event'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEventData<Object?> event, DateTime date) {
    // Extract event data
    final Map<String, dynamic> eventData = event.event as Map<String, dynamic>;
    final String? eventId = eventData['id']?.toString() ?? eventData['eventId']?.toString();

    if (eventId == null) {
      _handleError('Event ID not found', 'edit event');
      return;
    }

    // Initialize controllers with existing event data
    final TextEditingController titleController = TextEditingController(text: event.title ?? '');
    final TextEditingController descriptionController = TextEditingController(text: event.description ?? '');

    // Initialize date and times
    DateTime selectedDate = event.date ?? date;
    TimeOfDay startTime = TimeOfDay(hour: event.startTime?.hour ?? 8, minute: event.startTime?.minute ?? 0);
    TimeOfDay endTime = TimeOfDay(hour: event.endTime?.hour ?? 9, minute: event.endTime?.minute ?? 0);

    // Initialize color
    Color selectedColor = event.color ?? Colors.blue;

    // Show the dialog with the same UI as add event, but pre-filled
    _showEventDialog(
      context: context,
      title: 'Edit Event',
      titleController: titleController,
      descriptionController: descriptionController,
      selectedDate: selectedDate,
      startTime: startTime,
      endTime: endTime,
      selectedColor: selectedColor,
      onSave: (CalendarEventData<Object?> updatedEvent) {
        // Update the event in the backend
        _updateEvent(eventId, updatedEvent);
      },
    );
  }

  void _updateEvent(String eventId, CalendarEventData<Object?> updatedEvent) {
    try {
      print('Updating event with ID: $eventId');
      print('Updated event data: $updatedEvent');

      // Store the scaffold messenger for later use
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Updating event...')),
      );

      // Call the service to update the event
      _calendarService.updateEvent(eventId, updatedEvent).then((updatedEvent) {
        print('Event updated successfully: $updatedEvent');

        if (updatedEvent != null) {
          // Remove the old event and add the updated one
          try {
            // Find and remove the old event
            final events = eventController.events;
            CalendarEventData<Object?>? oldEvent;

            for (final event in events) {
              final eventData = event.event as Map<String, dynamic>?;
              if (eventData != null) {
                final id = eventData['id']?.toString() ?? eventData['eventId']?.toString();
                if (id == eventId) {
                  oldEvent = event;
                  break;
                }
              }
            }

            if (oldEvent != null) {
              eventController.remove(oldEvent);
              eventController.add(updatedEvent);

              // Show success message
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            } else {
              print('Could not find the old event to update');
              // Just add the updated event
              eventController.add(updatedEvent);

              // Show success message
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            }
          } catch (e) {
            print('Error updating event in controller: $e');
            _handleError(e, 'update event in calendar');
          }
        } else {
          // Show error message
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to update event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }).catchError((error) {
        print('Error updating event: $error');
        _handleError(error, 'update event');
      });
    } catch (e) {
      print('Exception in event update: $e');
      print('Stack trace: ${StackTrace.current}');
      _handleError(e, 'prepare for update');
    }
  }

  // Generic method for showing event dialog (used by both add and edit)
  void _showEventDialog({
    required BuildContext context,
    required String title,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required DateTime selectedDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Color selectedColor,
    required Function(CalendarEventData<Object?>) onSave,
  }) {
    // Function to pick date
    Future<void> _selectDate(BuildContext context, StateSetter setState) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
        });
      }
    }

    // Function to pick time
    Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );
      return picked;
    }

    // List of colors to choose from - match the colors in CalendarService._getColorFromName
    final List<Color> colorOptions = [
      Colors.blue,   // Default
      Colors.red,    // Red
      Colors.green,  // Green
      Colors.orange, // Orange
      Colors.purple, // Purple
      Colors.teal,   // Teal
    ];

    // Print the selected color for debugging
    void _printSelectedColor(Color color) {
      String colorName = 'unknown';
      if (color == Colors.blue) colorName = 'blue';
      else if (color == Colors.red) colorName = 'red';
      else if (color == Colors.green) colorName = 'green';
      else if (color == Colors.orange) colorName = 'orange';
      else if (color == Colors.purple) colorName = 'purple';
      else if (color == Colors.teal) colorName = 'teal';

      print('Selected color: $colorName ($color)');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Event Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () => _selectDate(context, setState),
                          child: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Start Time: '),
                        TextButton(
                          onPressed: () {
                            _selectTime(context, startTime).then((time) {
                              if (time != null) {
                                setState(() {
                                  startTime = time;
                                });
                              }
                            });
                          },
                          child: Text(
                            _formatTimeOfDay(startTime),
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('End Time: '),
                        TextButton(
                          onPressed: () {
                            _selectTime(context, endTime).then((time) {
                              if (time != null) {
                                setState(() {
                                  endTime = time;
                                });
                              }
                            });
                          },
                          child: Text(
                            _formatTimeOfDay(endTime),
                            style: const TextStyle(color: Color(0xFF255DE1)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Event Color:'),
                    const SizedBox(height: 5),
                    Container(
                      height: 50, // Fixed height for color options
                      child: Wrap(
                        spacing: 12, // Increased spacing
                        runSpacing: 12, // Added spacing between rows
                        children: colorOptions.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                                _printSelectedColor(color);
                              });
                            },
                            child: Container(
                              width: 40, // Increased size
                              height: 40, // Increased size
                              margin: EdgeInsets.all(4), // Added margin
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color ? Colors.black : Colors.transparent,
                                  width: 3, // Thicker border
                                ),
                                // Add shadow for better visibility
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      // Validate that end time is after start time
                      if (endTime.hour < startTime.hour ||
                          (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
                        // Show error dialog for invalid time selection
                        showDialog(
                          context: context,
                          barrierDismissible: false, // User must tap button to close dialog
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Invalid Time Selection'),
                              content: const Text('End time must be after start time. Please adjust your time selection.'),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              actions: [
                                TextButton(
                                  child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        return; // Don't proceed with event creation
                      }

                      try {
                        // Create the event locally first
                        print('Creating/updating event with title: ${titleController.text}');
                        print('Date: $selectedDate, Start: $startTime, End: $endTime');

                        // Create start and end time DateTime objects
                        final startDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute,
                        );

                        final endDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime.hour,
                          endTime.minute,
                        );

                        print('Start DateTime: $startDateTime');
                        print('End DateTime: $endDateTime');

                        // Print the selected color before creating the event
                        _printSelectedColor(selectedColor);

                        final eventData = CalendarEventData(
                          date: selectedDate,
                          title: titleController.text,
                          description: descriptionController.text,
                          startTime: startDateTime,
                          endTime: endDateTime,
                          color: selectedColor,
                          event: {'title': titleController.text}, // Temporary event data
                        );

                        print('Created event data with color: ${eventData.color}');

                        // Close the dialog
                        Navigator.of(context).pop();

                        // Call the onSave callback
                        onSave(eventData);
                      } catch (e) {
                        print('Exception in event dialog: $e');
                        print('Stack trace: ${StackTrace.current}');

                        // Show error directly with context since we're still in the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error preparing event: ${e.toString().substring(0, min(50, e.toString().length))}...'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    } else {
                      // Show error dialog if title is empty
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Text('Missing Title'),
                            content: const Text('Please enter a title for your event.'),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            actions: [
                              TextButton(
                                child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text(title == 'Edit Event' ? 'Update Event' : 'Add Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, {DateTime? initialDate}) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = initialDate ?? DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute);
    Color selectedColor = Colors.blue;

    // Use the generic event dialog for adding events
    _showEventDialog(
      context: context,
      title: 'Add New Event',
      titleController: titleController,
      descriptionController: descriptionController,
      selectedDate: selectedDate,
      startTime: startTime,
      endTime: endTime,
      selectedColor: selectedColor,
      onSave: (CalendarEventData<Object?> event) {
        // Store the scaffold messenger for later use
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Show loading indicator
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Creating event...')),
        );

        // Save to backend
        _calendarService.createEvent(event).then((createdEvent) {
          print('Event created successfully: $createdEvent');
          if (createdEvent != null) {
            // Validate the event before adding to the controller
            if (createdEvent.startTime == null || createdEvent.endTime == null) {
              print('Failed to add event: Start time or end time is null');

              // Show error in a dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Missing Time Information'),
                    content: const Text(
                      'The event could not be added to the calendar because either the start time or end time is missing. '
                      'Please try creating the event again with complete time information.'
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    actions: [
                      TextButton(
                        child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                },
              );
              return;
            }

            if (createdEvent.endTime!.isBefore(createdEvent.startTime!) ||
                createdEvent.endTime!.isAtSameMomentAs(createdEvent.startTime!)) {
              print('Failed to add event because of one of the given reasons:');
              print('1. Start time or end time might be null');
              print('2. endTime occurs before or at the same time as startTime.');
              print('Event data:');
              print('$createdEvent');

              // Show error in a dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Invalid Event Time'),
                    content: const Text(
                      'The event could not be added to the calendar because the end time is not after the start time. '
                      'This may be due to time zone conversion issues or data inconsistency.'
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    actions: [
                      TextButton(
                        child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                },
              );
              return;
            }

            // Add the event to the controller with the ID from the backend
            try {
              eventController.add(createdEvent);
              print('Event successfully added to controller');

              // Show a snackbar to confirm
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Event "${event.title}" added')),
              );
            } catch (e) {
              print('Error adding event to controller: $e');

              // Show error in a dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Calendar Error'),
                    content: Text(
                      'There was an error adding the event to the calendar: ${e.toString().substring(0, min(50, e.toString().length))}...\n\n'
                      'The event was created in the database but could not be displayed in the calendar.'
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    actions: [
                      TextButton(
                        child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          } else {
            // Show error message when event creation fails
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to create event. Please check your connection and try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }).catchError((error) {
          print('Error in createEvent callback: $error');
          // Show error message
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Error Creating Event'),
                content: Text(
                  'There was an error creating the event: ${error.toString().substring(0, min(50, error.toString().length))}...\n\n'
                  'Please try again or check your connection.'
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                actions: [
                  TextButton(
                    child: const Text('OK', style: TextStyle(color: Color(0xFF255DE1))),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }
}
