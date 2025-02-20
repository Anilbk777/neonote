// // lib/screens/page_list.dart
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:project/personalScreen/quicknotes.dart';

// class PageListScreen extends StatefulWidget {
//   @override
//   _PageListScreenState createState() => _PageListScreenState();
// }

// class _PageListScreenState extends State<PageListScreen> {
//   final FlutterSecureStorage _storage = FlutterSecureStorage();
//   List<dynamic> _pages = [];

//   Future<void> _fetchPages() async {
//     final token = await _storage.read(key: 'access_token');

//     if (token == null) return;

//     final response = await http.get(
//       Uri.parse('http://127.0.0.1:8000/apii/pages/'),
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     if (response.statusCode == 200) {
//       setState(() {
//         _pages = json.decode(response.body);
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _fetchPages();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('My Pages'),
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.add),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => CreatePageScreen()),
//           );
//         },
//       ),
//       body: ListView.builder(
//         itemCount: _pages.length,
//         itemBuilder: (context, index) {
//           final page = _pages[index];
//           return ListTile(
//             title: Text(page['title']),
//             subtitle: Text(page['content'].toString().substring(0, 50) + '...'),
//             onTap: () {
//               // Navigate to page detail screen
//             },
//           );
//         },
//       ),
//     );
//   }
// }
