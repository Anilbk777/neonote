import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:project/services/local_storage.dart'; // Use the same LocalStorage as other services

class CalendarService {
  // URL for the Django calendar events API
  static const String baseUrl = 'http://127.0.0.1:8000/api/calendar/api/events/'; // Use the API endpoint

  // Get the auth token using LocalStorage
  Future<String?> _getToken() async {
    try {
      // Get token from LocalStorage (same as other services)
      String? token = await LocalStorage.getToken();

      if (token != null && token.isNotEmpty) {
        print('✅ Using token from LocalStorage for calendar');
        return 'Bearer $token';
      } else {
        print('⚠️ No token found in LocalStorage for calendar');
        return null;
      }
    } catch (e) {
      print('❌ Error getting token for calendar: $e');
      return null;
    }
  }

  // Helper to create headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token ?? '',  // Token already includes 'Bearer ' prefix
    };
  }

  // Convert color from Flutter to Django format
  String _colorToHex(Color color) {
    final hex = '#${color.value.toRadixString(16).substring(2)}';
    print('Converting color to hex: $color -> $hex');
    return hex;
  }

  // Convert hex color from Django to Flutter Color
  Color _hexToColor(String hexColor) {
    print('Converting hex to color: $hexColor');
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    final color = Color(int.parse(hexColor, radix: 16));
    print('Converted hex to color: $hexColor -> $color');
    return color;
  }

  // Map color name to Flutter Color
  Color _getColorFromName(String colorName) {
    print('Converting color name to color: $colorName');
    Color color;
    switch (colorName) {
      case 'red':
        color = Colors.red;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'purple':
        color = Colors.purple;
        break;
      case 'teal':
        color = Colors.teal;
        break;
      case 'blue':
      default:
        color = Colors.blue;
        break;
    }
    print('Converted color name to color: $colorName -> $color');
    return color;
  }

  // Convert Django event to CalendarEventData
  CalendarEventData<Object?> _convertToCalendarEventData(Map<String, dynamic> event) {
    print('Converting event data: $event');
    final date = DateTime.parse(event['date']);

    // Parse start and end times
    final startTimeParts = event['start_time'].split(':');
    final endTimeParts = event['end_time'].split(':');

    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    final endTime = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
    );

    // Store the event ID in the event object for reference
    final eventData = {
      ...event,
      'eventId': event['id'].toString(),
    };

    // Determine the color to use
    Color eventColor;
    if (event['color'] != null) {
      print('Using hex color from event: ${event['color']}');
      eventColor = _hexToColor(event['color']);
    } else if (event['color_name'] != null) {
      print('Using color name from event: ${event['color_name']}');
      eventColor = _getColorFromName(event['color_name']);
    } else {
      print('No color info found, using default blue');
      eventColor = Colors.blue;
    }
    print('Final color for event: $eventColor');

    return CalendarEventData(
      title: event['title'],
      description: event['description'] ?? '',
      date: date,
      startTime: startTime,
      endTime: endTime,
      color: eventColor,
      event: eventData, // Store the original event data with ID
    );
  }

  // Get events for a specific month
  Future<List<CalendarEventData<Object?>>> getEventsForMonth(int year, int month) async {
    try {
      final headers = await _getHeaders();

      // Add a timeout to the request
      final url = '${baseUrl}month/?year=$year&month=$month';
      print('Fetching events from: $url');
      print('Using headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Successfully loaded ${data.length} events');
        return data.map((event) => _convertToCalendarEventData(event)).toList();
      } else {
        print('Failed to load events: ${response.statusCode}');
        // Return empty list for any error
        return [];
      }
    } catch (e) {
      print('Error fetching events: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      // Check if it's a connection error
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        print('Connection error: The Django server is not running. Please start the server.');
      }

      // Return empty list for any error
      return [];
    }
  }

  // Return empty list instead of sample events
  List<CalendarEventData<Object?>> _getSampleEvents() {
    // Return empty list - no sample events
    return [];
  }

  // Get events for a date range
  Future<List<CalendarEventData<Object?>>> getEventsForRange(DateTime start, DateTime end) async {
    try {
      final headers = await _getHeaders();
      final startFormatted = DateFormat('yyyy-MM-dd').format(start);
      final endFormatted = DateFormat('yyyy-MM-dd').format(end);

      final response = await http.get(
        Uri.parse('${baseUrl}range/?start_date=$startFormatted&end_date=$endFormatted'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((event) => _convertToCalendarEventData(event)).toList();
      } else {
        print('Failed to load events: ${response.statusCode}');
        // For testing purposes, return sample events when the server is not available
        if (response.statusCode == 404 || response.statusCode >= 500) {
          return _getSampleEvents().where((event) =>
            event.date.isAfter(start.subtract(const Duration(days: 1))) &&
            event.date.isBefore(end.add(const Duration(days: 1)))
          ).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error fetching events: $e');
      // For testing purposes, return sample events when there's a connection error
      return _getSampleEvents().where((event) =>
        event.date.isAfter(start.subtract(const Duration(days: 1))) &&
        event.date.isBefore(end.add(const Duration(days: 1)))
      ).toList();
    }
  }

  // Get events for a specific day
  Future<List<CalendarEventData<Object?>>> getEventsForDay(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateFormatted = DateFormat('yyyy-MM-dd').format(date);

      final response = await http.get(
        Uri.parse('${baseUrl}day/?date=$dateFormatted'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((event) => _convertToCalendarEventData(event)).toList();
      } else {
        print('Failed to load events: ${response.statusCode}');
        // For testing purposes, return sample events when the server is not available
        if (response.statusCode == 404 || response.statusCode >= 500) {
          return _getSampleEvents().where((event) =>
            event.date.year == date.year &&
            event.date.month == date.month &&
            event.date.day == date.day
          ).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error fetching events: $e');
      // For testing purposes, return sample events when there's a connection error
      return _getSampleEvents().where((event) =>
        event.date.year == date.year &&
        event.date.month == date.month &&
        event.date.day == date.day
      ).toList();
    }
  }

  // Create a new event
  Future<CalendarEventData<Object?>?> createEvent(CalendarEventData<Object?> event) async {
    try {
      // Validate event times
      if (event.startTime == null || event.endTime == null) {
        print('Failed to add event: Start time or end time is null');
        return null;
      }

      if (event.endTime!.isBefore(event.startTime!) || event.endTime!.isAtSameMomentAs(event.startTime!)) {
        print('Failed to add event: End time occurs before or at the same time as start time');
        return null;
      }
      print('Creating event: ${event.title} on ${event.date}');
      print('Event details: startTime=${event.startTime}, endTime=${event.endTime}, color=${event.color}');

      final headers = await _getHeaders();
      print('Headers: $headers');

      // Format the data for the API
      final Map<String, dynamic> eventData = {
        'title': event.title,
        'description': event.description ?? '',
        'date': DateFormat('yyyy-MM-dd').format(event.date),
        'start_time': DateFormat('HH:mm:ss').format(event.startTime ?? event.date),
        'end_time': DateFormat('HH:mm:ss').format(event.endTime ?? event.date),
        'color': _colorToHex(event.color),
      };

      print('Sending event data: $eventData');

      try {
        print('Sending POST request to: $baseUrl');
        print('With headers: $headers');
        print('And body: ${json.encode(eventData)}');

        final response = await http.post(
          Uri.parse(baseUrl),
          headers: headers,
          body: json.encode(eventData),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Connection timed out. Please check your server.');
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          return _convertToCalendarEventData(data);
        } else {
          print('Failed to create event: ${response.statusCode}');
          print('Response: ${response.body}');

          // Don't create mock events when server returns error
          if (response.statusCode == 404 || response.statusCode >= 500) {
            print('Server error: ${response.statusCode}');
            print('Cannot create event due to server error');
            return null;
          }

          return null;
        }
      } catch (httpError) {
        print('HTTP error: $httpError');
        throw httpError; // Re-throw to be caught by the outer try-catch
      }
    } catch (e) {
      print('Error creating event: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');

      // Check if it's a connection error
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        print('Connection error: The Django server is not running. Please start the server.');
      }

      // Don't create mock events when there's an exception
      print('Cannot create event due to exception');
      return null;
    }
  }

  // Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl$eventId/'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your server.');
        },
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting event: $e');

      // Don't simulate successful deletion
      print('Cannot delete event due to error');
      return false;
    }
  }

  // Update an event
  Future<CalendarEventData<Object?>?> updateEvent(String eventId, CalendarEventData<Object?> event) async {
    try {
      final headers = await _getHeaders();

      // Format the data for the API
      final Map<String, dynamic> eventData = {
        'title': event.title,
        'description': event.description,
        'date': DateFormat('yyyy-MM-dd').format(event.date),
        'start_time': DateFormat('HH:mm:ss').format(event.startTime ?? event.date),
        'end_time': DateFormat('HH:mm:ss').format(event.endTime ?? event.date),
        'color': _colorToHex(event.color),
      };

      final response = await http.put(
        Uri.parse('$baseUrl$eventId/'),
        headers: headers,
        body: json.encode(eventData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _convertToCalendarEventData(data);
      } else {
        print('Failed to update event: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error updating event: $e');
      return null;
    }
  }
}
