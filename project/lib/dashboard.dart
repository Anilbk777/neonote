
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData(); // Ensure it runs after the first frame is built
    });
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

  // Check if token was cleared from LocalStorage
  String? storedToken = await LocalStorage.getToken(); 
  print("Token after logout: $storedToken");  // Should print null after logout

  // Optionally, check if the token is also cleared from SharedPreferences (for debug purposes)
  String? storedPrefToken = prefs.getString('access_token');
  print("Token from SharedPreferences after logout: $storedPrefToken"); 
  
  String? storedPages = prefs.getString('user_pages');
  print("Stored pages after logout: $storedPages");  // Should print null after logout

  // Clear in-memory data if using provider (ensure your PagesProvider has a clearPages method)

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
                  const Text(
                    'Recents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                    child: Row(
                      children: List.generate(
                        4,
                        (index) => Card(
                          child: Container(
                            width: 120, // Set a fixed width for each item
                            padding: const EdgeInsets.all(16.0),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book,
                                    color: Color.fromARGB(255, 37, 93, 225)),
                                SizedBox(height: 8),
                                Text('Diary', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
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
