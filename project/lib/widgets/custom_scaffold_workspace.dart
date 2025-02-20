// import 'package:flutter/material.dart';
// import 'package:project/dashboard.dart';

// class CustomScaffoldWorkspace extends StatefulWidget {
//   final String selectedPage;
//   final Function(String) onItemSelected;
//   final Widget body;

//   CustomScaffoldWorkspace({
//     required this.selectedPage,
//     required this.onItemSelected,
//     required this.body,
//   });

//   @override
//   _CustomScaffoldWorkspaceState createState() => _CustomScaffoldWorkspaceState();
// }

// class _CustomScaffoldWorkspaceState extends State<CustomScaffoldWorkspace> {
//   bool _isAdminExpanded = false; // Tracks if the "Admin" section is expanded
//   List<String> personalSpacePages = ['Diary', 'Quick Notes', 'Goals', 'Task List'];
//   List<String> favoritePages = []; // Separate list for favorite pages

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Row(
//         children: [
//           // Sidebar
//           Expanded(
//             flex: 1,
//             child: Container(
//               color: const Color(0xFFEFEFF4),
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(16.0),
//                       child: const Text(
//                         'NeoNote',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Color.fromARGB(255, 37, 93, 225),
//                         ),
//                       ),
//                     ),
//                     const Divider(),
//                     // Admin Section
//                     ListTile(
//                       leading: const Icon(Icons.admin_panel_settings, color: Colors.black54),
//                       title: const Text('Admin'),
//                       onTap: () {
//                         setState(() {
//                           _isAdminExpanded = !_isAdminExpanded; // Toggle the Admin section
//                         });
//                       },
//                     ),
//                     if (_isAdminExpanded) ...[
//                       Padding(
//                         padding: const EdgeInsets.only(left: 16.0),
//                         child: ListTile(
//                           leading: const Icon(Icons.switch_left, color: Colors.black54),
//                           title: const Text('Switch to Personal Space'),
//                           onTap: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(builder: (context) => DashboardPage()),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                     const Divider(),
//                     _buildSidebarItem(Icons.home, 'Home', context),
//                     _buildSidebarItem(Icons.inbox, 'Inbox', context),
//                     const Divider(),
//                     // Favorites Section
//                     Row(
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Text(
//                             'Favorites',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add, color: Colors.black54),
//                           onPressed: () {
//                             _showAddPageDialog(context, 'Favorites');
//                           },
//                         ),
//                       ],
//                     ),
//                     // Display favorite pages
//                     for (var page in favoritePages)
//                       _buildSidebarItem(Icons.favorite, page, context),
//                     const Divider(),
//                     // WorkSpace Section
//                     Row(
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Text(
//                             'WorkSpace',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add, color: Colors.black54),
//                           onPressed: () {
//                             _showAddPageDialog(context, 'WorkSpace');
//                           },
//                         ),
//                       ],
//                     ),
//                     for (var page in personalSpacePages)
//                       _buildSidebarItem(Icons.note, page, context),
//                     const Divider(),
//                     _buildSidebarItem(Icons.calendar_today, 'Calendar', context),
//                     _buildSidebarItem(Icons.file_copy, 'Templates', context),
//                     _buildSidebarItem(Icons.delete, 'Bin', context),
//                     const SizedBox(height: 20),
//                     Center(
//                       child: ElevatedButton.icon(
//                         onPressed: () {},
//                         icon: const Icon(Icons.group),
//                         label: const Text('Invite Members'),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Main Content
//           Expanded(
//             flex: 4,
//             child: widget.body,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarItem(IconData icon, String label, BuildContext context) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.black54),
//       title: Text(label),
//       onTap: () {
//         widget.onItemSelected(label); // Notify the parent about the selection
//       },
//       selected: widget.selectedPage == label,
//       selectedTileColor: const Color.fromARGB(255, 37, 93, 225),
//     );
//   }

//   // Dialog to Add New Page
//   void _showAddPageDialog(BuildContext context, String category) {
//     final TextEditingController _controller = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Add New $category Page'),
//           content: TextField(
//             controller: _controller,
//             decoration: const InputDecoration(
//               hintText: 'Enter page name',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (_controller.text.isNotEmpty) {
//                   setState(() {
//                     if (category == 'Favorites') {
//                       favoritePages.add(_controller.text); // Add to favorites
//                     } else if (category == 'WorkSpace') {
//                       personalSpacePages.add(_controller.text); // Add to personal space
//                     }
//                   });
//                 }
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
