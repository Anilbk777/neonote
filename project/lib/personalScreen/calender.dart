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

  // Add separate ScrollControllers for different scrollable widgets
  final ScrollController _monthListScrollController = ScrollController();
  final ScrollController _dialogScrollController = ScrollController();

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

  @override
  void dispose() {
    // Dispose of all ScrollControllers when the widget is disposed
    _monthListScrollController.dispose();
    _dialogScrollController.dispose();
    super.dispose();
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
      // Store a reference to the ScaffoldMessenger to avoid using a potentially invalid context
      final scaffoldMessengerState = ScaffoldMessenger.of(context);

      scaffoldMessengerState.showSnackBar(
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
              // Use the stored reference to hide the snackbar
              scaffoldMessengerState.hideCurrentSnackBar();
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
      // Load events for current month only
      final now = DateTime.now();

      print('CALENDAR: Initial load - fetching events for current month');
      // Create a new EventController
      eventController = EventController();

      // Load events for current month only
      final currentMonth = DateTime(now.year, now.month, 1);
      print('CALENDAR: Loading events for month ${currentMonth.year}-${currentMonth.month}');

      final monthEvents = await _calendarService.getEventsForMonth(currentMonth.year, currentMonth.month);

      print('CALENDAR: Loaded ${monthEvents.length} events for current month');

      // Add events to the controller
      eventController.addAll(monthEvents);

      // Log all events for debugging
      for (var event in monthEvents) {
        print('CALENDAR: Initial load event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
      }
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

  // WINDOWS STYLE: Direct API call with forced refresh
  Future<void> _loadEventsForFocusedDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new EventController instead of clearing the existing one
      eventController = EventController();
      print('WINDOWS STYLE: Created new EventController');

      switch (_calendarView) {
        case CalendarViewType.month:
          // Get the first day of the focused month
          final focusedMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
          print('WINDOWS STYLE: Loading events for month: ${focusedMonth.year}-${focusedMonth.month}');

          // Load events for the current month only
          print('WINDOWS STYLE: Loading events for focused month ${focusedMonth.year}-${focusedMonth.month}');
          final currentMonthEvents = await _calendarService.getEventsForMonth(focusedMonth.year, focusedMonth.month);

          print('WINDOWS STYLE: Loaded ${currentMonthEvents.length} events for current month');

          // Log all events for debugging
          for (var event in currentMonthEvents) {
            print('WINDOWS STYLE: Event: ${event.title} on ${DateFormat('yyyy-MM-dd').format(event.date)}');
          }

          // Add events to the new controller
          print('WINDOWS STYLE: Adding ${currentMonthEvents.length} events to controller');
          eventController.addAll(currentMonthEvents);
          break;

        case CalendarViewType.week:
          // For week view, get the start and end of the week (Sunday to Saturday)
          // Calculate the start of the week (Sunday) for the focused date
          final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
          final weekEnd = weekStart.add(const Duration(days: 6));
          print('WINDOWS STYLE: Loading events for week: ${weekStart.toString()} to ${weekEnd.toString()}');
          final events = await _calendarService.getEventsForRange(weekStart, weekEnd);
          eventController.addAll(events);
          break;

        case CalendarViewType.day:
          // For day view, just get the events for that day
          print('WINDOWS STYLE: Loading events for day: ${_focusedDate.toString()}');
          final events = await _calendarService.getEventsForDay(_focusedDate);
          eventController.addAll(events);
          break;
      }

      // Force a complete rebuild of the calendar view
      setState(() {
        print('WINDOWS STYLE: Forcing complete rebuild');
      });

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
        onPressed: () {
          // Always use today's date when adding from the FAB
          final now = DateTime.now();
          _showAddEventDialog(context, initialDate: now);
        },
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
                          onPressed: () async {
                            setState(() {
                              _focusedDate = DateTime.now();
                            });
                            await _jumpToToday();
                          },
                          tooltip: 'Today',
                        ),

                        // Month/Year selector button only for month view
                        if (_calendarView == CalendarViewType.month)
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            onPressed: () => _showMonthYearPicker(context),
                            tooltip: 'Select Month/Year',
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
                // Only show month/year picker in month view
                GestureDetector(
                  onTap: () {
                    if (_calendarView == CalendarViewType.month) {
                      _showMonthYearPicker(context);
                    }
                  },
                  child: _buildDateHeader(),
                ),
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
      onPressed: () async {
        if (_calendarView != view) {
          setState(() {
            _calendarView = view;
            _isLoading = true; // Show loading indicator
          });

          // If switching to week view, make sure we're showing the current week
          if (view == CalendarViewType.week) {
            // Calculate the start of the current week (Sunday)
            final now = DateTime.now();
            final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
            _focusedDate = currentWeekStart;
            _weekViewKey.currentState?.jumpToWeek(currentWeekStart);
          }

          // If switching to day view, make sure we're showing the current day
          if (view == CalendarViewType.day) {
            final now = DateTime.now();
            _focusedDate = now;
            _dayViewKey.currentState?.jumpToDate(now);
          }

          // Load appropriate events for the selected view
          await _loadEventsForFocusedDate();

          setState(() {
            _isLoading = false;
          });
        }
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
        // Calculate week start (Sunday) and end (Saturday)
        // For Sunday start, we need to calculate differently
        // Sunday is 7 in DateTime.weekday (1 is Monday, 7 is Sunday)
        final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
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

  Future<void> _showMonthYearPicker(BuildContext context) async {
    // Get the current month and year
    int selectedMonth = _focusedDate.month;
    int selectedYear = _focusedDate.year;

    // Show a dialog with month and year pickers
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Month and Year'),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SizedBox(
                width: 300, // Fixed narrower width
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month dropdown
                  Row(
                    children: [
                      const Text('Month: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text(_getMonthName(index + 1)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Year dropdown
                  Row(
                    children: [
                      const Text('Year: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(11, (index) {
                          // Show 5 years in the past and 5 years in the future
                          return DropdownMenuItem<int>(
                            value: DateTime.now().year - 5 + index,
                            child: Text('${DateTime.now().year - 5 + index}'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedYear = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
                ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    // Jump to the selected month and year
                    final newDate = DateTime(selectedYear, selectedMonth, 1);
                    print('WINDOWS STYLE: Month/Year picker selected date: ${newDate.year}-${newDate.month}');

                    // Use the outer setState to update the widget state
                    this.setState(() {
                      _focusedDate = newDate;
                      _isLoading = true; // Show loading indicator
                    });

                    // First load events for the new month and adjacent months
                    print('WINDOWS STYLE: Loading events for month: ${newDate.year}-${newDate.month}');
                    await _loadEventsForFocusedDate();

                    // Then jump to the new month
                    print('WINDOWS STYLE: Jumping to month: ${newDate.year}-${newDate.month}');
                    _monthViewKey.currentState?.jumpToMonth(newDate);

                    // Force a rebuild to ensure the calendar shows the correct events
                    this.setState(() {
                      print('WINDOWS STYLE: Rebuild complete for: ${newDate.year}-${newDate.month}');
                    });
                  },
                  child: const Text(
                    'Go',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWeekPicker(BuildContext context) async {
    // First, let the user pick a date
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // Calculate the start of the week (Sunday) for the picked date
      // Sunday is 7 in DateTime.weekday (1 is Monday, 7 is Sunday)
      final weekStart = picked.subtract(Duration(days: picked.weekday % 7));

      setState(() {
        _focusedDate = weekStart;
        _isLoading = true; // Show loading indicator
      });

      // Jump to the new week
      _weekViewKey.currentState?.jumpToWeek(weekStart);

      // Load events for the new week
      await _loadEventsForFocusedDate();

      // Force a rebuild to ensure the calendar shows the correct events
      setState(() {});
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _focusedDate) {
      setState(() {
        _focusedDate = picked;
        _isLoading = true; // Show loading indicator
      });

      switch (_calendarView) {
        case CalendarViewType.month:
          _monthViewKey.currentState?.jumpToMonth(picked);
          break;
        case CalendarViewType.week:
          _weekViewKey.currentState?.jumpToWeek(picked);
          break;
        case CalendarViewType.day:
          _dayViewKey.currentState?.jumpToDate(picked);
          break;
      }

      // Load events for the new date
      await _loadEventsForFocusedDate();

      // Force a rebuild to ensure the calendar shows the correct events
      setState(() {});
    }
  }

  Future<void> _jumpToToday() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final now = DateTime.now();

    switch (_calendarView) {
      case CalendarViewType.month:
        _focusedDate = DateTime(now.year, now.month, 1);
        _monthViewKey.currentState?.jumpToMonth(now);
        break;
      case CalendarViewType.week:
        // Calculate the start of the current week (Sunday)
        final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
        _focusedDate = currentWeekStart;
        _weekViewKey.currentState?.jumpToWeek(currentWeekStart);
        break;
      case CalendarViewType.day:
        _focusedDate = now;
        _dayViewKey.currentState?.jumpToDate(now);
        break;
    }

    // Load events for today
    await _loadEventsForFocusedDate();

    // Force a rebuild to ensure the calendar shows the correct events
    setState(() {
      _isLoading = false;
    });
  }

  void _previousPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // Calculate the previous month date
        final prevMonth = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
        setState(() {
          _focusedDate = prevMonth;
        });
        // Jump directly to the previous month instead of using animation
        _monthViewKey.currentState?.jumpToMonth(prevMonth);
        // Explicitly load events for the new month
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.week:
        // Calculate the previous week date
        final prevWeek = _focusedDate.subtract(const Duration(days: 7));
        setState(() {
          _focusedDate = prevWeek;
        });
        // Jump directly to the previous week instead of using animation
        _weekViewKey.currentState?.jumpToWeek(prevWeek);
        // Explicitly load events for the new week
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.day:
        // Calculate the previous day date
        final prevDay = _focusedDate.subtract(const Duration(days: 1));
        setState(() {
          _focusedDate = prevDay;
        });
        // Jump directly to the previous day instead of using animation
        _dayViewKey.currentState?.jumpToDate(prevDay);
        // Explicitly load events for the new day
        _loadEventsForFocusedDate();
        break;
    }
  }

  void _nextPage() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // Calculate the next month date
        final nextMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
        setState(() {
          _focusedDate = nextMonth;
        });
        // Jump directly to the next month instead of using animation
        _monthViewKey.currentState?.jumpToMonth(nextMonth);
        // Explicitly load events for the new month
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.week:
        // Calculate the next week date
        final nextWeek = _focusedDate.add(const Duration(days: 7));
        setState(() {
          _focusedDate = nextWeek;
        });
        // Jump directly to the next week instead of using animation
        _weekViewKey.currentState?.jumpToWeek(nextWeek);
        // Explicitly load events for the new week
        _loadEventsForFocusedDate();
        break;
      case CalendarViewType.day:
        // Calculate the next day date
        final nextDay = _focusedDate.add(const Duration(days: 1));
        setState(() {
          _focusedDate = nextDay;
        });
        // Jump directly to the next day instead of using animation
        _dayViewKey.currentState?.jumpToDate(nextDay);
        // Explicitly load events for the new day
        _loadEventsForFocusedDate();
        break;
    }
  }

  Widget _buildCalendarView() {
    switch (_calendarView) {
      case CalendarViewType.month:
        // SINGLE MONTH VIEW: Show only the current month with all dates
        return Container(
          height: 650, // Increased height to ensure all dates are fully visible
          // Set a minimum height to ensure cells have enough space for events
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom calendar header with day names and dates
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: _buildDayHeaders(),
                ),
              ),
              // Month view
              Expanded(
                child: MonthView(
                  key: _monthViewKey,
                  controller: eventController,
                  // Windows-style calendar configuration
                  showBorder: true,
                  cellAspectRatio: 1.0, // Square cells to provide more space for events
                  initialMonth: _focusedDate,
                  hideDaysNotInMonth: true, // Hide days not in the current month
                  // Enable page navigation
                  onPageChange: (date, page) {
                    _loadEventsForFocusedDate();
                  },
                  // Make sure all dates are shown
                  minMonth: DateTime(1900, 1, 1),
                  maxMonth: DateTime(2100, 12, 31),
                  // Hide the built-in weekday header since we're using our custom header
                  weekDayBuilder: (index) => const SizedBox.shrink(),
                  // Set first day of week to Sunday (index 0)
                  startDay: WeekDays.sunday,
                  // Show dates from adjacent months
                  onEventTap: (events, date) {
                    _showEventDetailsDialog(context, events, date);
                  },
                  onCellTap: (events, date) {
                    // Handle cell tap in the cellBuilder with GestureDetector
                  },
                  // Hide the header as we're using our custom header
                  headerBuilder: (date) => const SizedBox.shrink(),
                  cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                    if (!isInMonth && hideDaysNotInMonth) {
                      return const SizedBox.shrink(); // Hide cells not in the current month
                    }

                    // Filter events to only show events for this specific date
                    List<CalendarEventData<Object?>> filteredEvents = [];

                    // The calendar_view package can pass events in different formats
                    // We need to handle each case carefully
                    if (events != null) {
                      try {
                        // Case 1: events is a List<CalendarEventData>
                        if (events is List) {
                          for (var i = 0; i < (events as List).length; i++) {
                            var event = events[i];
                            if (event is CalendarEventData<Object?>) {
                              if (event.date.year == date.year &&
                                  event.date.month == date.month &&
                                  event.date.day == date.day) {
                                filteredEvents.add(event);
                              }
                            }
                          }
                        }
                        // Case 2: events is a single CalendarEventData
                        else if (events is CalendarEventData<Object?>) {
                          var event = events as CalendarEventData<Object?>;
                          if (event.date.year == date.year &&
                              event.date.month == date.month &&
                              event.date.day == date.day) {
                            filteredEvents.add(event);
                          }
                        }
                      } catch (e) {
                        print('Error filtering events: $e');
                        // If there's an error, we'll just show an empty list
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        if (filteredEvents.isNotEmpty) {
                          _showEventDetailsDialog(context, filteredEvents, date);
                        } else {
                          // Check if the date is in the past
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final selectedDate = DateTime(date.year, date.month, date.day);

                          print('Cell tap - Today: $today');
                          print('Cell tap - Selected date: $selectedDate');
                          print('Cell tap - Is same as today: ${selectedDate.isAtSameMomentAs(today)}');
                          print('Cell tap - Is after today: ${selectedDate.isAfter(today)}');

                          // Only show add event dialog for current or future dates
                          if (selectedDate.isAtSameMomentAs(today) || selectedDate.isAfter(today)) {
                            _showAddEventDialog(context, initialDate: date);
                          } else {
                            // Store a reference to the ScaffoldMessenger to avoid using a potentially invalid context
                            final scaffoldMessengerState = ScaffoldMessenger.of(context);
                            // Show message that past dates are not allowed
                            scaffoldMessengerState.showSnackBar(
                              const SnackBar(
                                content: Text('You cannot create events for past dates.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.blue.withOpacity(0.3) : Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isToday ? Colors.blue : Colors.grey.shade300,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Date number at the top
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: isInMonth ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            // Events list
                            if (filteredEvents.isNotEmpty)
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
                                  itemCount: filteredEvents.length > 3 ? 3 : filteredEvents.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final event = filteredEvents[index];

                                    // If this is the 3rd event and there are more, show a "+X more" indicator
                                    if (index == 2 && filteredEvents.length > 3) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 2.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          "+${filteredEvents.length - 2} more",
                                          style: const TextStyle(
                                            fontSize: 9.0,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }

                                    // Format the time for display
                                    String timeStr = '';
                                    if (event.startTime != null) {
                                      timeStr = DateFormat('h:mm a').format(event.startTime!);
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 2.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: event.color.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              event.title ?? '',
                                              style: const TextStyle(
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      case CalendarViewType.week:
        return WeekView(
          key: _weekViewKey,
          controller: eventController,
          onEventTap: (events, date) {
            // Handle the event tap
            _showEventDetailsDialog(context, events, date);
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
          // Set first day of week to Sunday
          startDay: WeekDays.sunday,
          // Custom weekday names (SUN, MON, TUE, etc.) with dates
          weekDayBuilder: (date) {
            // Convert date to day of week index (0 = Sunday, 1 = Monday, etc.)
            final dayIndex = date.weekday % 7; // Convert to 0-based index with Sunday as 0
            final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

            // Check if this is today
            final now = DateTime.now();
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
                color: isToday ? Colors.blue.withOpacity(0.1) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Combine day name and date in a more compact layout
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: dayNames[dayIndex],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        TextSpan(
                          text: '\n${date.day}', // Add date on new line
                          style: TextStyle(
                            color: isToday ? const Color(0xFF255DE1) : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          // Hide the header as we're using our custom header
          weekPageHeaderBuilder: (startDate, endDate) => const SizedBox.shrink(),
          eventTileBuilder: (date, events, boundary, startTime, endTime) {
            // Filter events to only show events for this specific date
            List<CalendarEventData<Object?>> filteredEvents = [];
            if (events is List<CalendarEventData<Object?>>) {
              filteredEvents = events.where((event) {
                return event.date.year == date.year &&
                       event.date.month == date.month &&
                       event.date.day == date.day;
              }).toList();
            }

            // Custom event tile for week view
            if (filteredEvents.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: filteredEvents[0].color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  filteredEvents[0].title ?? '',
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
          onEventTap: (events, date) {
            // Handle the event tap
            _showEventDetailsDialog(context, events, date);
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
            // Filter events to only show events for this specific date
            List<CalendarEventData<Object?>> filteredEvents = [];
            if (events is List<CalendarEventData<Object?>>) {
              filteredEvents = events.where((event) {
                return event.date.year == date.year &&
                       event.date.month == date.month &&
                       event.date.day == date.day;
              }).toList();
            }

            // Custom event tile for day view
            if (filteredEvents.isEmpty) return const SizedBox.shrink();
            return Container(
              decoration: BoxDecoration(
                color: filteredEvents[0].color.withOpacity(0.8),
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
                        filteredEvents[0].title ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (filteredEvents[0].description?.isNotEmpty ?? false)
                      Flexible(
                        child: Text(
                          filteredEvents[0].description ?? '',
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

  // Build day headers for the calendar (SUN, MON, TUE, etc.)
  List<Widget> _buildDayHeaders() {
    final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final List<Widget> headers = [];

    // Create headers for each day of the week
    for (int i = 0; i < 7; i++) {
      headers.add(
        Expanded(
          child: Center(
            child: Text(
              dayNames[i],
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    return headers;
  }

  void _showEventDetailsDialog(BuildContext context, dynamic eventOrEvents, DateTime date) {
    // Convert to list if it's a single event
    List<CalendarEventData<Object?>> events;
    if (eventOrEvents is List<CalendarEventData<Object?>>) {
      events = eventOrEvents;
    } else if (eventOrEvents is CalendarEventData<Object?>) {
      events = [eventOrEvents];
    } else {
      events = [];
    }

    // Filter events to only show events for this specific date
    events = events.where((event) {
      return event.date.year == date.year &&
             event.date.month == date.month &&
             event.date.day == date.day;
    }).toList();

    // Sort events by start time
    events.sort((a, b) {
      if (a.startTime == null && b.startTime == null) return 0;
      if (a.startTime == null) return -1;
      if (b.startTime == null) return 1;
      return a.startTime!.compareTo(b.startTime!);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.event, color: Color(0xFF255DE1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Events on ${DateFormat('EEEE, MMM d, yyyy').format(date)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF255DE1),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No events for this date',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      // Extract event ID for edit/delete functionality
                      final Map<String, dynamic> eventData = event.event as Map<String, dynamic>? ?? {};
                      final String? eventId = eventData['id']?.toString() ?? eventData['eventId']?.toString();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: event.color.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Event header with color and title
                            Container(
                              decoration: BoxDecoration(
                                color: event.color.withOpacity(0.8),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.title ?? 'No Title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Edit icon
                                  if (eventId != null)
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _showEditEventDialog(context, event, date);
                                      },
                                    ),
                                  const SizedBox(width: 8),
                                  // Delete icon
                                  if (eventId != null)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        // Show confirmation dialog
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Delete Event'),
                                              content: const Text('Are you sure you want to delete this event?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(); // Close confirmation dialog
                                                    Navigator.of(context).pop(); // Close event details dialog

                                                    // Delete the event
                                                    _calendarService.deleteEvent(eventId).then((success) {
                                                      if (success) {
                                                        // Remove from controller
                                                        eventController.remove(event);

                                                        // Show success message
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Event "${event.title}" deleted')),
                                                        );
                                                      } else {
                                                        // Show error message
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Failed to delete event'),
                                                            backgroundColor: Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    });
                                                  },
                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            // Event details
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${DateFormat('h:mm a').format(event.startTime ?? date)} - ${DateFormat('h:mm a').format(event.endTime ?? date)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Description (if any)
                                  if (event.description?.isNotEmpty ?? false)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Description:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            event.description ?? '',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            // Add event button (only for current or future dates)
            Builder(
              builder: (context) {
                // Convert to date-only objects for accurate comparison
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final dateOnly = DateTime(date.year, date.month, date.day);

                if (dateOnly.isAtSameMomentAs(today) || dateOnly.isAfter(today)) {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showAddEventDialog(context, initialDate: date);
                    },
                    child: const Text('Add Event', style: TextStyle(color: Color(0xFF255DE1))),
                  );
                } else {
                  return const SizedBox.shrink(); // Don't show button for past dates
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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

      // Store the scaffold messenger for later use - get it from the current context
      // This ensures we have a valid reference even if the widget is disposed
      final scaffoldMessengerState = ScaffoldMessenger.of(context);

      // Show loading indicator
      scaffoldMessengerState.showSnackBar(
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

              // Show success message using the stored reference
              scaffoldMessengerState.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            } else {
              print('Could not find the old event to update');
              // Just add the updated event
              eventController.add(updatedEvent);

              // Show success message using the stored reference
              scaffoldMessengerState.showSnackBar(
                SnackBar(content: Text('Event "${updatedEvent.title}" updated')),
              );
            }
          } catch (e) {
            print('Error updating event in controller: $e');
            // Use the stored reference to show error
            if (mounted) {
              _handleError(e, 'update event in calendar');
            } else {
              // If widget is no longer mounted, use the stored reference directly
              scaffoldMessengerState.showSnackBar(
                SnackBar(
                  content: Text('Error updating event: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Show error message using the stored reference
          scaffoldMessengerState.showSnackBar(
            const SnackBar(
              content: Text('Failed to update event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }).catchError((error) {
        print('Error updating event: $error');
        // Use the stored reference to show error
        if (mounted) {
          _handleError(error, 'update event');
        } else {
          // If widget is no longer mounted, use the stored reference directly
          scaffoldMessengerState.showSnackBar(
            SnackBar(
              content: Text('Error updating event: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      print('Exception in event update: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _handleError(e, 'prepare for update');
      } else {
        // If widget is no longer mounted, we can't show an error message
        print('Widget not mounted, cannot show error message');
      }
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
      // Get today's date with time set to midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Convert selectedDate to date-only for accurate comparison
      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      print('Date picker - Today: $today');
      print('Date picker - Selected date: $selectedDateOnly');
      print('Date picker - Is before today: ${selectedDateOnly.isBefore(today)}');

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateOnly.isBefore(today) ? today : selectedDate,
        firstDate: today, // Set firstDate to today to prevent selecting past dates
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
          print('Date picker - New selected date: $selectedDate');
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
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              content: SizedBox(
                width: 300, // Fixed narrower width
                child: SingleChildScrollView(
                controller: _dialogScrollController, // Use dedicated controller for dialog
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
                      child: SingleChildScrollView(
                        physics: NeverScrollableScrollPhysics(), // Prevent scrolling
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
                    ),
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              content: SizedBox(
                                width: 300, // Fixed narrower width
                                child: const Text('End time must be after start time. Please adjust your time selection.'),
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF255DE1),
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
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

                        // Use Navigator.of(context).context to get a valid context
                        // This ensures we're using a context that's still valid
                        final navigatorContext = Navigator.of(context).context;
                        ScaffoldMessenger.of(navigatorContext).showSnackBar(
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
                            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            content: SizedBox(
                              width: 300, // Fixed narrower width
                              child: const Text('Please enter a title for your event.'),
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF255DE1),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text(
                    title == 'Edit Event' ? 'Update Event' : 'Add Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, {DateTime? initialDate}) {
    // Store a reference to the ScaffoldMessenger before showing the dialog
    // This ensures we can safely use it even after the dialog is closed
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = initialDate ?? _focusedDate; // Use the tapped date or focused date

    print('Opening add event dialog for date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}');

    // Check if the selected date is in the past
    final currentDateTime = DateTime.now();
    final today = DateTime(currentDateTime.year, currentDateTime.month, currentDateTime.day);

    // Convert selectedDate to just date (no time) for accurate comparison
    final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // A date is in the past only if it's strictly before today
    final isPastDate = selectedDateOnly.isBefore(today);

    if (isPastDate) {
      // Show error message - can't create events for past dates
      scaffoldMessengerState.showSnackBar(
        const SnackBar(
          content: Text('You cannot create events for past dates.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Don't show the dialog
    }

    // Debug info
    print('Today: $today');
    print('Selected date: $selectedDateOnly');
    print('Is past date: $isPastDate');

    // Set reasonable default times (current time for start, +1 hour for end)
    final currentTimeOfDay = TimeOfDay.now();
    TimeOfDay startTime = currentTimeOfDay;
    TimeOfDay endTime = TimeOfDay(hour: (currentTimeOfDay.hour + 1) % 24, minute: currentTimeOfDay.minute);
    Color selectedColor = Colors.green; // Changed default to green based on the error log

    // Use the generic event dialog for adding events
    _showEventDialog(
      context: context,
      title: 'Add New Event',
      titleController: titleController,
      descriptionController: descriptionController,
      selectedDate: selectedDate, // Pass the correct date
      startTime: startTime,
      endTime: endTime,
      selectedColor: selectedColor,
      onSave: (CalendarEventData<Object?> event) async {
        // Use the stored scaffold messenger reference instead of getting it from context
        // Show loading indicator
        scaffoldMessengerState.showSnackBar(
          const SnackBar(content: Text('Creating event...')),
        );

        print('Creating event on date: ${event.date.year}-${event.date.month}-${event.date.day}');
        print('Event details: ${event.title}, Start: ${event.startTime}, End: ${event.endTime}');

        // Save to backend
        try {
          print('Attempting to create event with title: ${event.title}');
          print('Event date: ${event.date}, color: ${event.color}');

          final createdEvent = await _calendarService.createEvent(event);

          if (createdEvent != null) {
            print('Event created successfully: ${createdEvent.title} on ${createdEvent.date}');
            eventController.add(createdEvent); // Add the event to the controller
            scaffoldMessengerState.showSnackBar(
              SnackBar(content: Text('Event "${event.title}" added')),
            );

            // Reload events to ensure the new event is properly displayed
            _loadEventsForFocusedDate();
          } else {
            print('Failed to create event - backend returned null');
            scaffoldMessengerState.showSnackBar(
              const SnackBar(
                content: Text('Failed to create event. Please make sure the Django server is running.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );

            // For testing/demo purposes, add the event locally if backend fails
            print('Adding event locally for demonstration purposes');
            final localEvent = CalendarEventData(
              date: event.date,
              title: event.title,
              description: event.description,
              startTime: event.startTime,
              endTime: event.endTime,
              color: event.color,
              event: {'id': 'local-${DateTime.now().millisecondsSinceEpoch}', 'title': event.title},
            );

            eventController.add(localEvent);
            _loadEventsForFocusedDate();

            scaffoldMessengerState.showSnackBar(
              SnackBar(
                content: Text('Added event "${event.title}" locally (demo mode)'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          print('Exception during event creation: $e');
          scaffoldMessengerState.showSnackBar(
            SnackBar(
              content: Text('Error creating event: ${e.toString().substring(0, min(50, e.toString().length))}...'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );

          // For testing/demo purposes, add the event locally if exception occurs
          print('Adding event locally after exception for demonstration purposes');
          final localEvent = CalendarEventData(
            date: event.date,
            title: event.title,
            description: event.description,
            startTime: event.startTime,
            endTime: event.endTime,
            color: event.color,
            event: {'id': 'local-${DateTime.now().millisecondsSinceEpoch}', 'title': event.title},
          );

          eventController.add(localEvent);
          _loadEventsForFocusedDate();
        }
      },
    );
  }
}