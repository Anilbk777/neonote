// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/page.dart';
import 'page_screen.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Page> pages = []; // Store pages

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Retrieve JWT token

    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:8000//apii/pages/'), // Update with your Django API endpoint
      headers: {
        'Authorization': 'Bearer $token', // Pass the token for authentication
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        pages = data.map((page) => Page.fromJson(page)).toList();
      });
    } else {
      // Handle error (e.g., network error, unauthorized access)
      print('Failed to load pages');
    }
  }

  // Handle creating a new page
  Future<void> _createPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Retrieve JWT token

    final response = await http.post(
      Uri.parse(
          'http://127.0.0.1:8000//apii/pages/'), // Update with your Django API endpoint
      headers: {
        'Authorization': 'Bearer $token', // Pass the token for authentication
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': 'New Page ${pages.length + 1}',
        'content': 'Content for the new page',
      }),
    );

    if (response.statusCode == 201) {
      _fetchPages(); // Refresh the page list after creating a new page
    } else {
      print('Failed to create page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notion Clone Dashboard')),
      body: pages.isEmpty
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : ListView.builder(
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(pages[index].title),
                  onTap: () {
                    // Navigate to the selected page's details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PageScreen(
                            pageId: pages[index].id,
                            pageTitle: pages[index].title),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPage, // Create new page
        child: Icon(Icons.add),
        tooltip: 'Create New Page',
      ),
    );
  }
}
