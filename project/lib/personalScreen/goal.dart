
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/widgets/goal_cards.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:project/providers/notification_provider.dart';
import 'package:project/models/notification_model.dart';
import 'goal_helpers.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final List<Goal> _goals = [];
  final List<Goal> _filteredGoals = [];
  final _goalController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _completionDate;
  bool _isLoading = false;
  bool _isSearchActive = false;
  bool _noGoalsFound = false;
  bool _hasReminder = false;
  DateTime? _reminderDateTime;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _goalController.addListener(_clearSearchOnGoalFocus);
    _searchController.addListener(_clearGoalOnSearchFocus);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchOnGoalFocus() {
    if (_goalController.text.isNotEmpty) {
      _searchController.clear();
    }
  }

  void _clearGoalOnSearchFocus() {
    if (_searchController.text.isNotEmpty) {
      _goalController.clear();
    }
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final goals = await GoalService.fetchGoals();
      setState(() {
        _goals.clear();
        _goals.addAll(goals);
        _filteredGoals.clear();
        _filteredGoals.addAll(goals);
        _goals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt descending
        _isLoading = false;
      });
      _filterGoals();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load goals: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  List<Goal> get _activeGoals {
    return _filteredGoals.where((goal) => !goal.isCompleted).toList();
  }

  List<Goal> get _completedGoals {
    final now = DateTime.now();
    return _filteredGoals.where((goal) {
      if (!goal.isCompleted) return false;
      final completionTime = goal.completionTime;
      if (completionTime == null) return false;
      return now.difference(completionTime).inDays <= 30;
    }).toList();
  }

  void _filterGoals() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGoals.clear();
      _filteredGoals.addAll(_goals.where((goal) {
        String goalTitle = goal.title.toLowerCase();
        String startDate = DateFormat.yMMMd().format(goal.startDate).toLowerCase();
        String completionDate = DateFormat.yMMMd().format(goal.completionDate).toLowerCase();
        return goalTitle.contains(query) ||
            startDate.contains(query) ||
            completionDate.contains(query);
      }));
      _noGoalsFound = _filteredGoals.isEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredGoals.clear();
      _filteredGoals.addAll(_goals);
      _noGoalsFound = false;
    });
  }

  Future<void> _handleAddGoal() async {
    setState(() {
      _isLoading = true;
    });

    // Debug print to check the reminder date time before adding the goal
    if (_hasReminder && _reminderDateTime != null) {
      print('Adding goal with reminder date time: ${_reminderDateTime.toString()}');
      print('Current time: ${DateTime.now().toString()}');
      print('Time difference in minutes: ${_reminderDateTime!.difference(DateTime.now()).inMinutes}');
    }

    await addGoal(
      context,
      _goalController,
      _startDate,
      _completionDate,
      setState,
      hasReminder: _hasReminder,
      reminderDateTime: _reminderDateTime,
    );

    // Clear the controllers and dates after adding a goal
    _goalController.clear();
    _startDate = null;
    _completionDate = null;
    _hasReminder = false;
    _reminderDateTime = null;
    await _loadGoals();
  }

  Future<void> _handleToggleCompletion(Goal goal) async {
    // Optimistically update the UI
    setState(() {
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        goal.completionTime = DateTime.now();
      } else {
        goal.completionTime = null;
      }
      _filteredGoals.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort goals
    });

    try {
      // Make the API call to update the goal's status
      await GoalService.updateGoal(
        goalId: goal.id,
        title: goal.title,
        startDate: goal.startDate,
        completionDate: goal.completionDate,
        isCompleted: goal.isCompleted,
        completionTime: goal.completionTime,
      );
    } catch (e) {
      // Revert the UI update if the API call fails
      setState(() {
        goal.isCompleted = !goal.isCompleted;
        if (goal.isCompleted) {
          goal.completionTime = DateTime.now();
        } else {
          goal.completionTime = null;
        }
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to update goal status: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleEditGoal(int index) async {
    setState(() {
      _isLoading = true;
    });
    await editGoal(
      context,
      index,
      _goals,
      setState,
    );
    await _loadGoals();
  }

  Future<void> _handleDeleteGoal(int index) async {
    setState(() {
      _isLoading = true;
    });
    await deleteGoal(
      context,
      index,
      _goals,
      setState,
      (bool loading) {
        setState(() {
          _isLoading = loading;
        });
      },
    );
    setState(() {
      _filteredGoals.clear();
      _filteredGoals.addAll(_goals);
      _noGoalsFound = _filteredGoals.isEmpty;
      _isLoading = false;
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF255DE1),
        ),
      ),
    );
  }

  // New method to show the Add Goal dialog using the same inputs as before.
  Future<void> _showAddGoalDialog() async {
    // Use a temporary state for the dialog's date selections to keep them in sync with the page
    DateTime? dialogStartDate = _startDate;
    DateTime? dialogCompletionDate = _completionDate;
    bool dialogHasReminder = _hasReminder;

    // Set default reminder time to current time + 2 minutes for testing
    final now = DateTime.now();

    // We want to use the time exactly as it was entered by the user
    // without any time zone conversion
    DateTime? dialogReminderDateTime;
    if (_reminderDateTime != null) {
      dialogReminderDateTime = _reminderDateTime;
    } else {
      // Set a default reminder time (current time + 2 minutes)
      dialogReminderDateTime = now.add(const Duration(minutes: 2));
    }

    // For time picker with AM/PM format
    TimeOfDay? reminderTime = dialogReminderDateTime != null
        ? TimeOfDay(hour: dialogReminderDateTime.hour, minute: dialogReminderDateTime.minute)
        : TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // StatefulBuilder allows us to manage the dialog's internal state.
          builder: (context, setStateDialog) {
            // We're now using the formatTimeOfDayTo12Hour function from notification_model.dart

            // Use a simple Dialog with fixed width
            return AlertDialog(
              title: const Text('Add Goal'),
              content: Container(
                width: 400, // Fixed width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _goalController,
                        decoration: InputDecoration(
                          labelText: 'What\'s your goal?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.stars),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dialogStartDate == null
                                ? 'Select Start Date'
                                : DateFormat.yMMMd().format(dialogStartDate!),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dialogStartDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  dialogStartDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dialogCompletionDate == null
                                ? 'Select Completion Date'
                                : DateFormat.yMMMd().format(dialogCompletionDate!),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dialogCompletionDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  dialogCompletionDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Reminder Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications, color: Color(0xFF255DE1)),
                              const SizedBox(width: 8),
                              const Text(
                                'Set Reminder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: dialogHasReminder,
                            activeColor: const Color(0xFF255DE1),
                            onChanged: (value) {
                              setStateDialog(() {
                                dialogHasReminder = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (dialogHasReminder) ...[
                        const SizedBox(height: 16),
                        // Reminder Date
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reminder Date & Time (Nepal Time)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Date Picker
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      dialogReminderDateTime != null
                                          ? DateFormat.yMMMd().format(dialogReminderDateTime!)
                                          : 'Select Date',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Get current date/time for validation
                                      final DateTime now = DateTime.now();

                                      // Show date picker with current date as minimum
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: dialogReminderDateTime ?? now,
                                        firstDate: now, // Can't pick dates in the past
                                        lastDate: DateTime(2100),
                                      );

                                      if (pickedDate != null) {
                                        // Preserve the time part when updating the date
                                        // This ensures we keep the same time but update the date

                                        // Get the time components from the current reminder time
                                        // or use the current time if no reminder time is set
                                        int hour = reminderTime?.hour ?? now.hour;
                                        int minute = reminderTime?.minute ?? now.minute;

                                        // Create a new DateTime with the selected date and current time
                                        // This will be in the local time zone (Nepal time)
                                        final newDateTime = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          hour,
                                          minute,
                                        );

                                        // Debug print to check the time
                                        print('GOAL DATE PICKER - Selected date: ${pickedDate.toString()}');
                                        print('GOAL DATE PICKER - Selected time: $hour:$minute');
                                        print('GOAL DATE PICKER - New reminder date time: ${newDateTime.toString()}');
                                        print('GOAL DATE PICKER - New reminder time zone offset: ${newDateTime.timeZoneOffset}');
                                        print('GOAL DATE PICKER - Current time: ${now.toString()}');
                                        print('GOAL DATE PICKER - Current time zone offset: ${now.timeZoneOffset}');
                                        print('GOAL DATE PICKER - Time difference: ${newDateTime.difference(now)}');
                                        print('GOAL DATE PICKER - Time difference in minutes: ${newDateTime.difference(now).inMinutes}');
                                        print('GOAL DATE PICKER - Time difference in seconds: ${newDateTime.difference(now).inSeconds}');

                                        setStateDialog(() {
                                          dialogReminderDateTime = newDateTime;
                                        });
                                      }
                                    },
                                    child: const Text('Change'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Time Picker
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reminderTime != null
                                          ? formatTimeOfDayTo12Hour(reminderTime!)
                                          : 'Select Time',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Show time picker with 12-hour format
                                      TimeOfDay? pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: reminderTime ?? TimeOfDay.now(),
                                        builder: (BuildContext context, Widget? child) {
                                          return MediaQuery(
                                            data: MediaQuery.of(context).copyWith(
                                              alwaysUse24HourFormat: false, // Use 12-hour format
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );

                                      if (pickedTime != null) {
                                        setStateDialog(() {
                                          reminderTime = pickedTime;

                                          // Update the full date time with the new time
                                          // This preserves the date but updates the time
                                          if (dialogReminderDateTime != null) {
                                            // Create a new DateTime with the selected date and time
                                            // We want to store the time exactly as selected by the user
                                            // without any time zone conversion

                                            // Get the date components from the current reminder date time
                                            final year = dialogReminderDateTime!.year;
                                            final month = dialogReminderDateTime!.month;
                                            final day = dialogReminderDateTime!.day;

                                            // Create a new DateTime with the selected time
                                            // This will be in the local time zone (Nepal time)
                                            final newDateTime = DateTime(
                                              year,
                                              month,
                                              day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );

                                            // Debug print to check the time
                                            final now = DateTime.now();
                                            print('GOAL TIME PICKER - User selected time: ${pickedTime.hour}:${pickedTime.minute}');
                                            print('GOAL TIME PICKER - Created new reminder date time: ${newDateTime.toString()}');
                                            print('GOAL TIME PICKER - New reminder time zone offset: ${newDateTime.timeZoneOffset}');
                                            print('GOAL TIME PICKER - Current time: ${now.toString()}');
                                            print('GOAL TIME PICKER - Current time zone offset: ${now.timeZoneOffset}');
                                            print('GOAL TIME PICKER - Time difference: ${newDateTime.difference(now)}');
                                            print('GOAL TIME PICKER - Time difference in minutes: ${newDateTime.difference(now).inMinutes}');
                                            print('GOAL TIME PICKER - Time difference in seconds: ${newDateTime.difference(now).inSeconds}');

                                            dialogReminderDateTime = newDateTime;
                                          } else {
                                            // If no date was set yet, use today's date with the selected time
                                            final now = DateTime.now();
                                            final newDateTime = DateTime(
                                              now.year,
                                              now.month,
                                              now.day,
                                              pickedTime.hour,
                                              pickedTime.minute,
                                            );

                                            // Debug print to check the time
                                            print('Selected time: ${pickedTime.hour}:${pickedTime.minute}');
                                            print('New reminder date time: ${newDateTime.toString()}');
                                            print('Current time: ${now.toString()}');
                                            print('Time difference in minutes: ${newDateTime.difference(now).inMinutes}');

                                            dialogReminderDateTime = newDateTime;
                                          }
                                        });
                                      }
                                    },
                                    child: const Text('Change'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Nepal Time Zone info
                              const Text(
                                'Nepal Time (UTC+5:45)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear inputs if needed and close dialog.
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update the state with the dialog inputs
                    setState(() {
                      _startDate = dialogStartDate;
                      _completionDate = dialogCompletionDate;
                      _hasReminder = dialogHasReminder;
                      _reminderDateTime = dialogHasReminder ? dialogReminderDateTime : null;
                    });
                    await _handleAddGoal();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add Goal'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make sure we have access to the NotificationProvider
    // This will ensure it's available in the widget tree
    Provider.of<NotificationProvider>(context, listen: false);

    return CustomScaffold(
      selectedPage: 'Goals',
      onItemSelected: (page) {
        // Existing navigation logic remains intact.
      },
      // Added floating action button to add goals.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF255DE1),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isSearchActive,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF255DE1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '✨ Dreams to Achieve ✨',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search goals by name or date...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _filterGoals();
                            _goalController.clear();
                          },
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_noGoalsFound)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Goal not found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.red[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_activeGoals.isNotEmpty) ...[
                              _buildSectionHeader('Active Goals 🎯'),
                              ..._activeGoals.map(
                                (goal) => GoalCard(
                                  goal: goal,
                                  onToggleCompletion: () {
                                    _handleToggleCompletion(goal);
                                  },
                                  onEdit: () => _handleEditGoal(_goals.indexOf(goal)),
                                  onDelete: () => _handleDeleteGoal(_goals.indexOf(goal)),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (_completedGoals.isNotEmpty) ...[
                              _buildSectionHeader('Completed Goals ✅'),
                              ..._completedGoals.map(
                                (goal) => GoalCard(
                                  goal: goal,
                                  onToggleCompletion: () {
                                    _handleToggleCompletion(goal);
                                  },
                                  onEdit: () => _handleEditGoal(_goals.indexOf(goal)),
                                  onDelete: () => _handleDeleteGoal(_goals.indexOf(goal)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading || _isSearchActive)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
