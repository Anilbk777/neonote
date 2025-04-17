
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/widgets/custom_scaffold.dart'; // Import your reusable scaffold
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/personalScreen/content_page.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/services/diary_service.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // String _selectedPage = "Home"; // Tracks which page is active
  // String _fullName = 'Loading...';
  String _selectedPage = "Home";
  String _fullName = 'Loading...';
  List<String> _pages = [];
  List<dynamic> _recentDiaries = [];
  bool _isLoadingDiaries = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData(); // Ensure it runs after the first frame is built
      _fetchRecentDiaries(); // Fetch recent diary entries
      _fetchUserPages(); // Fetch user's content pages
    });
  }

  // Fetch user's content pages
  Future<void> _fetchUserPages() async {
    try {
      // Access the PagesProvider and fetch pages
      final pagesProvider = Provider.of<PagesProvider>(context, listen: false);
      await pagesProvider.fetchPages();
      print('✅ User pages fetched successfully');
    } catch (e) {
      print('❌ Error fetching user pages: $e');
    }
  }

  // Fetch recent diary entries
  Future<void> _fetchRecentDiaries() async {
    try {
      setState(() {
        _isLoadingDiaries = true;
      });

      // Create an instance of DiaryService
      final diaryService = DiaryService();

      // Fetch all diary entries
      final entries = await diaryService.getAllEntries();

      // Sort entries by updated_at or created_at in descending order (newest first)
      entries.sort((a, b) {
        final dateA = a.updatedAt ?? a.createdAt ?? a.date;
        final dateB = b.updatedAt ?? b.createdAt ?? b.date;
        return dateB.compareTo(dateA);
      });

      // Take only the 5 most recent entries
      final recentEntries = entries.take(5).toList();

      // Convert DiaryEntry objects to maps for easier use in the UI
      final recentDiaries = recentEntries.map((entry) => {
        'id': entry.id,
        'title': entry.title,
        'content': entry.content,
        'date': entry.date.toIso8601String(),
        'backgroundColor': entry.backgroundColor,
        'textColor': entry.textColor,
        'template': entry.template,
      }).toList();

      setState(() {
        _recentDiaries = recentDiaries;
        _isLoadingDiaries = false;
      });

      print('Fetched ${_recentDiaries.length} recent diary entries');
    } catch (e) {
      print('Error fetching recent diaries: $e');
      setState(() {
        _isLoadingDiaries = false;
      });
    }
  }




  Future<void> _fetchUserData() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token');
      String? token = await LocalStorage.getToken();

      if (token == null) {
        print("Token is null. Redirecting to login.");
        _redirectToLogin();
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/accounts/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('full_name')) {
          setState(() {
            _fullName = data['full_name'];
          });
        } else {
          print("Key 'full_name' not found in response: $data");
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

void _redirectToLogin() {
  Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
}

// Navigate to create a new diary entry
Future<void> _navigateToNewDiary() async {
  try {
    print('Navigating to new diary page');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiaryPage(),
      ),
    );

    if (result != null && mounted) {
      print('New diary created, refreshing list');
      await _fetchRecentDiaries(); // Refresh the recent diaries
    }
  } catch (e) {
    print('Error navigating to new diary page: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating new diary entry')),
      );
    }
  }
}

// Navigate to a diary entry
Future<void> _openDiary(dynamic diary) async {
  try {
    print('Opening diary: $diary');

    // Pass the diary map directly (no need to serialize)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewDiaryPage(initialData: diary),
      ),
    );

    if (result != null && mounted) {
      print('Diary updated, refreshing list');
      await _fetchRecentDiaries(); // Refresh the recent diaries
    }
  } catch (e) {
    print('Error opening diary: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening diary entry')),
      );
    }
  }
}



Future<void> _logout() async {
  // Clear token from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('user_pages'); // Remove token from SharedPreferences

  // Clear token from LocalStorage (flutter_secure_storage)
  await LocalStorage.clearToken(); // Assuming LocalStorage handles secure storage

  // Clear any cached data or pages
  setState(() {
    _fullName = 'Loading...';  // Reset user data
    _pages = [];  // Clear cached pages or session data
  });

  // Clear in-memory data using provider
  Provider.of<PagesProvider>(context, listen: false).clearPages();
  print('✅ Cleared pages from PagesProvider');

  // Check if token was cleared from LocalStorage
  String? storedToken = await LocalStorage.getToken();
  print("Token after logout: $storedToken");  // Should print null after logout

  // Optionally, check if the token is also cleared from SharedPreferences (for debug purposes)
  String? storedPrefToken = prefs.getString('access_token');
  print("Token from SharedPreferences after logout: $storedPrefToken");

  String? storedPages = prefs.getString('user_pages');
  print("Stored pages after logout: $storedPages");  // Should print null after logout

  // Redirect to login page
  _redirectToLogin();
}



  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: _selectedPage,
      onItemSelected: (page) {
        setState(() {
          _selectedPage = page;
        });
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Container(
            color: const Color.fromARGB(255, 37, 93, 225),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Spacer(), // This pushes the text to the center
                Text(
                  'Good Morning, $_fullName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(), // This ensures the text stays centered
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          // Dashboard Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.menu_book,
                            size: 24,
                            color: Color(0xFF255DE1),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recent Diaries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/diary');
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("View All"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF255DE1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _isLoadingDiaries
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _recentDiaries.isEmpty
                      ? const Center(
                          child: Text(
                            'No recent diary entries',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                          child: Row(
                            children: [
                              // Add a "New Entry" card at the beginning
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: _navigateToNewDiary,
                                    child: Container(
                                      width: 120,
                                      height: 160,
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.add_circle_outline, size: 30, color: Color(0xFF255DE1)),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'New Entry',
                                            style: TextStyle(fontSize: 14),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Generate cards for recent diary entries
                              ...List.generate(
                                _recentDiaries.length,
                                (index) {
                                  final diary = _recentDiaries[index];
                                  final date = DateTime.parse(diary['date']);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: InkWell(
                                        onTap: () => _openDiary(diary),
                                        child: Container(
                                          width: 120,
                                          height: 160,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE3F2FD),
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 2,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.menu_book, size: 30, color: Color(0xFF255DE1)),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                diary['title'] ?? DateFormat('MMM d').format(date),
                                                style: const TextStyle(fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                DateFormat('MMM d').format(date),
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Upcoming Events Section
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.calendar_today,
                          color: Color.fromARGB(255, 37, 93, 225)),
                      title: Text('Today, December 22'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('9 AM, My meeting in Zoom'),
                          Text('11 AM, Lunch Time'),
                        ],
                      ),
                    ),
                  ),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.calendar_today,
                          color: Color.fromARGB(255, 37, 93, 225)),
                      title: Text('Saturday, December 25'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('10 AM, Grocery Store'),
                          Text('12 AM, Lamachaur'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
