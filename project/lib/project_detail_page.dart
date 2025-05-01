// import 'package:flutter/material.dart';
// import 'package:project/widgets/custom_scaffold_workspace.dart';
// import 'package:project/work_page.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:project/services/local_storage.dart';
// import 'package:project/widgets/project_task_list.dart'; // Import the new widget

// class ProjectDetailPage extends StatefulWidget {
//   final String title;
//   final String description;
//   final int projectId;
//   final bool isHostedByUser;

//   const ProjectDetailPage({
//     Key? key,
//     required this.title,
//     required this.description,
//     required this.projectId,
//     required this.isHostedByUser,
//   }) : super(key: key);

//   @override
//   _ProjectDetailPageState createState() => _ProjectDetailPageState();
// }

// class _ProjectDetailPageState extends State<ProjectDetailPage> {
//   List<Map<String, dynamic>> members = [];
//   bool isLoading = true;
//   Map<String, dynamic>? host; // Variable to store host details
//   String error = '';
//   bool _isEditing = false;
//   bool _isSaving = false; // To show loading indicator while saving

//   late TextEditingController _titleController;
//   late TextEditingController _descriptionController;
//   // Remove task-related state variables from here
//   // bool _isLoadingTasks = true;
//   // List<dynamic> _projectTasks = [];
//   // String? _tasksError;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with initial values
//     _titleController = TextEditingController(text: widget.title);
//     _descriptionController = TextEditingController(text: widget.description);
//     fetchProjectDetails();
//     // Remove _fetchProjectTasks call from here
//   }

//   Future<void> fetchProjectDetails() async {
//     try {
//       setState(() {
//         isLoading = true;
//         error = '';
//       });

//       final token = await LocalStorage.getToken();
//       if (token == null) {
//         setState(() {
//           error = 'Not authenticated';
//           isLoading = false;
//         });
//         return;
//       }

//       final response = await http.get(
//         // Use 10.0.2.2 for Android emulator accessing localhost
//         Uri.parse('http://10.0.2.2:8000/api/work/projects/${widget.projectId}/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         try {
//           final data = json.decode(response.body);
//           // Update controllers if not currently editing, in case data changed externally
//           if (!_isEditing) {
//             _titleController.text = data['name'] ?? widget.title;
//             _descriptionController.text = data['description'] ?? widget.description;
//           }
//           // Extract host details
//           final ownerData = data['owner'];

//           setState(() {
//             members = List<Map<String, dynamic>>.from(data['members'] ?? []);
//             // Store host details separately
//             host = ownerData != null ? Map<String, dynamic>.from(ownerData) : null;
//             isLoading = false;
//           });
//         } catch (e) {
//           setState(() {
//             error = 'Error parsing response: ${e.toString()}';
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           error = 'Failed to load project details: ${response.statusCode}';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         error = 'Error connecting to server: ${e.toString()}';
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _saveProjectDetails() async {
//     if (_isSaving) return; // Prevent multiple save attempts

//     setState(() {
//       _isSaving = true;
//     });

//     final token = await LocalStorage.getToken();
//     if (token == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Not authenticated')),
//         );
//         setState(() { _isSaving = false; });
//       }
//       return;
//     }

//     try {
//       final response = await http.patch(
//         // Use 10.0.2.2 for Android emulator accessing localhost
//         Uri.parse('http://10.0.2.2:8000/api/work/projects/${widget.projectId}/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//         body: json.encode({
//           'name': _titleController.text,
//           'description': _descriptionController.text,
//         }),
//       );

//       if (mounted) { // Check mounted before updating state/showing snackbar
//         if (response.statusCode == 200) {
//           setState(() {
//             _isEditing = false; // Exit edit mode on success
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Project updated successfully'), backgroundColor: Colors.green),
//           );
//           // Optionally refetch details to confirm, though PATCH should return updated data
//           // await fetchProjectDetails();
//         } else {
//           final errorData = json.decode(response.body);
//           final errorMessage = errorData.toString(); // Adjust based on backend error structure
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to update project: $errorMessage'), backgroundColor: Colors.red),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving project: ${e.toString()}'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() { _isSaving = false; });
//       }
//     }
//   }

//   Future<void> _inviteTeamMember(BuildContext context, String email) async {
//     final persistentContext = context; // Use the local context instead

//     try {
//       final token = await LocalStorage.getToken(); // Corrected class name
//       if (token == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Not authenticated')),
//           );
//         }
//         return;
//       }

//       final response = await http.post(
//         // Use 10.0.2.2 for Android emulator accessing localhost
//         Uri.parse('http://10.0.2.2:8000/api/work/projects/${widget.projectId}/invite_member/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//         body: json.encode({'email': email}),
//       );

//       if (response.statusCode == 201) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Invitation sent successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else if (response.statusCode == 400) {
//         final errorData = json.decode(response.body);
//         String errorMessage = errorData['error'] ?? 'Failed to send invitation';
//         if (errorMessage.contains('You are the host')) {
//           if (mounted) showDialog( // Add mounted check
//             context: persistentContext,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Host Action'),
//                 content: const Text('You are the host of this project and cannot invite yourself.'),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else if (errorMessage.contains('already a member')) {
//           if (mounted) showDialog( // Add mounted check
//             context: persistentContext,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('User Already a Member'),
//                 content: const Text('The user you are trying to invite is already a member of this project.'),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           if (mounted) showDialog( // Add mounted check
//             context: persistentContext,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Error'),
//                 content: Text(errorMessage),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         }
//       } else {
//         final errorData = json.decode(response.body);
//         String errorMessage = errorData['error'] ?? 'Failed to send invitation';
//         if (mounted) {
//           showDialog( // Mounted check already done
//             context: persistentContext,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: const Text('Error'),
//                 content: Text(errorMessage),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _showInviteDialog(BuildContext context) {
//     final emailController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Invite Team Member'),
//           content: TextField(
//             controller: emailController,
//             decoration: const InputDecoration(
//               labelText: 'Email Address',
//               hintText: 'Enter team member\'s email',
//             ),
//             keyboardType: TextInputType.emailAddress,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (emailController.text.isNotEmpty) {
//                   _inviteTeamMember(context, emailController.text);
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('Send Invitation'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildMemberChip(Map<String, dynamic> member) {
//     final bool isOwner = member['isOwner'] == true;

//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 8,
//       ),
//       decoration: BoxDecoration(
//         color: isOwner 
//           ? const Color(0xFF255DE1).withOpacity(0.2) // Host chip background
//           : Colors.teal.withOpacity(0.1), // Member chip background (changed to teal)
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isOwner 
//             ? const Color(0xFF255DE1).withOpacity(0.4)
//             : Colors.blue.withOpacity(0.3),
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isOwner ? Icons.star : Icons.person,
//             size: 16,
//             color: isOwner 
//               ? const Color(0xFF255DE1)
//               : Colors.teal[700], // Member icon color (changed to teal)
//           ),
//           const SizedBox(width: 8),
//           Text(
//             member['full_name'] ?? 'Unknown',
//             style: TextStyle(
//               fontSize: 14,
//               color: isOwner 
//                 ? const Color(0xFF255DE1)
//                 : Colors.teal[800], // Member text color (changed to teal)
//               fontWeight: isOwner
//                 ? FontWeight.bold
//                 : FontWeight.w500,
//             ),
//           ),
//           if (isOwner) ...[
//             const SizedBox(width: 4),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF255DE1).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Text(
//                 'Host',
//                 style: TextStyle(
//                   fontSize: 10,
//                   color: Color(0xFF255DE1),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ScaffoldMessenger(
//       child: CustomScaffoldWorkspace(
//         selectedPage: 'Work',
//         onItemSelected: (String page) {
//           if (page == 'Work') {
//             Navigator.of(context).pushReplacement(
//               MaterialPageRoute(
//                 builder: (context) => const WorkPage(),
//               ),
//             );
//           }
//         },
//         body: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//               decoration: const BoxDecoration(
//                 color: Colors.blueAccent,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     offset: Offset(0, 2),
//                     blurRadius: 4,
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                     Expanded(
//                       child: _isEditing
//                           ? TextField(
//                               controller: _titleController,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                               decoration: const InputDecoration(
//                                 border: InputBorder.none,
//                                 isDense: true,
//                                 hintText: 'Project Title',
//                                 hintStyle: TextStyle(color: Colors.white54),
//                               ),
//                             )
//                           : Text(
//                               _titleController.text, // Use controller text
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                     ),
//                     if (widget.isHostedByUser) // Show edit/save/cancel only for hosted projects
//                       if (_isEditing) ...[
//                         IconButton(
//                           icon: const Icon(Icons.cancel, color: Colors.white),
//                           tooltip: 'Cancel Edit',
//                           onPressed: () {
//                             setState(() {
//                               _isEditing = false;
//                               // Reset controllers to original values
//                               _titleController.text = widget.title;
//                               _descriptionController.text = widget.description;
//                             });
//                           },
//                         ),
//                         IconButton(
//                           icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
//                           tooltip: 'Save Changes',
//                           onPressed: _isSaving ? null : _saveProjectDetails,
//                         ),
//                       ] else
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.white),
//                           tooltip: 'Edit Project',
//                           onPressed: () {
//                             setState(() {
//                               _isEditing = true;
//                             });
//                           },
//                         ),
//                     // Always show invite button if hosted by user
//                     if (widget.isHostedByUser) IconButton(
//                       icon: const Icon(Icons.person_add, color: Colors.white), // Keep invite button
//                       onPressed: () => _showInviteDialog(context),
//                     ),
//                     if (widget.isHostedByUser) // Show delete icon only for hosted projects
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.white),
//                         onPressed: () => _showDeleteConfirmationDialog(context),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 padding: const EdgeInsets.all(24.0),
//                 child: ListView( // Use ListView to allow scrolling if content exceeds height
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.1),
//                             spreadRadius: 2,
//                             blurRadius: 15,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           _isEditing
//                               ? TextField(
//                                   controller: _descriptionController,
//                                   maxLines: null, // Allow multiple lines
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.black87, // Darker text for editing
//                                     height: 1.6,
//                                   ),
//                                   decoration: const InputDecoration(
//                                     hintText: 'Enter project description',
//                                     border: OutlineInputBorder(),
//                                     isDense: true,
//                                   ),
//                                 )
//                               : Text(
//                                   _descriptionController.text.isEmpty ? 'No description provided.' : _descriptionController.text, // Use controller text
//                                   style: TextStyle(fontSize: 16, color: _descriptionController.text.isEmpty ? Colors.black38 : Colors.black54, height: 1.6),
//                           ),
//                           // Display Host Info Here
//                           if (!_isEditing && host != null) ...[
//                             const SizedBox(height: 24), // Add some spacing
//                             Container( // Wrap in a container for potential background/padding
//                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.orange.withOpacity(0.1), // Light orange background
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min, // Keep row tight
//                               children: [
//                                 Icon(Icons.star, size: 18, color: Colors.orange[800]), // Slightly larger icon
//                                 const SizedBox(width: 6),
//                                 // Apply styling to the Text widget
//                                 Text('Host: ${host!['full_name'] ?? 'Unknown'}',
//                                   style: TextStyle(fontSize: 16, color: Colors.orange[900], fontWeight: FontWeight.bold)), // Increased size, bolder, darker orange
//                               ],
//                             ), // Row ends here
//                           ), // Container ends here
//                           ],
//                           // End Host Info
//                           const SizedBox(height: 32),
//                           const Text(
//                             'Team',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           if (isLoading)
//                             const Center(
//                               child: CircularProgressIndicator(),
//                             )
//                           else if (error.isNotEmpty)
//                             Text(
//                               error,
//                               style: const TextStyle(color: Colors.red),
//                             )
//                           // Display Team Members (excluding the host)
//                           else
//                             Builder( // Use Builder to calculate filtered members
//                               builder: (context) {
//                                 // Filter out the host first
//                                 final actualMembers = members
//                                     .where((member) => host == null || member['id'] != host!['id'])
//                                     .toList();

//                                 if (actualMembers.isEmpty) {
//                                   // If no members other than the host
//                                   return const Padding(
//                                     padding: EdgeInsets.only(top: 8.0), // Add some padding
//                                     child: Text(
//                                       'No other team members yet.',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.black54,
//                                       ),
//                                     ),
//                                   );
//                                 } else {
//                                   // If there are members other than the host
//                                   return Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       const Text('Team Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
//                                       const SizedBox(height: 8),
//                                       Wrap(
//                                         spacing: 8,
//                                         runSpacing: 8,
//                                         children: actualMembers.map((member) => _buildMemberChip(member)).toList(),
//                                       ),
//                                     ],
//                                   );
//                                 }
//                               },
//                             ),
//                         ],
//                       ),
//                     ),
//                    const SizedBox(height: 24), // Spacing between containers
//                     // Task List Placeholder Container
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.grey.withOpacity(0.1),
//                             spreadRadius: 2,
//                             blurRadius: 15,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Column( // Use Column to structure title and list
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Project Tasks', // Title for the section
//                             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                           ),
//                           const SizedBox(height: 16),
//                           // Replace the placeholder text/logic with the new widget
//                           ProjectTaskList(projectId: widget.projectId),
//                           // TODO: Add a button/icon here to add new tasks later
//                         ],
//                         ),
//                       ),
//                     ),
//                    ],

//                  ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


//   void _showDeleteConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Project'),
//           content: const Text('Are you sure you want to delete this project?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await _deleteProject();
//               },
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _deleteProject() async {
//     try {
//       final token = await LocalStorage.getToken();
//       if (token == null) {
//         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Not authenticated')),
//         );
//         return;
//       }
      
//       final response = await http.delete(
//         // Use 10.0.2.2 for Android emulator accessing localhost
//         Uri.parse('http://10.0.2.2:8000/api/work/projects/${widget.projectId}/'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 204) {
//         // Show SnackBar *before* navigation
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Project deleted successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           // Navigate after showing feedback
//           Navigator.of(context).pushAndRemoveUntil(
//              MaterialPageRoute(builder: (context) => const WorkPage()),
//              (Route<dynamic> route) => false, // Remove all previous routes
//           );
//         }
//       } else {
//         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to delete project: ${response.statusCode}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) 
//         ScaffoldMessenger.of(context).showSnackBar( // Remove 'const' here
//           SnackBar(
//           content: Text('Error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

// =======================================================================================================================


import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart';
import 'package:project/work_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';
import 'package:project/widgets/project_task_list.dart'; // Import the new widget

class ProjectDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final int projectId;
  final bool isHostedByUser;

  const ProjectDetailPage({
    Key? key,
    required this.title,
    required this.description,
    required this.projectId,
    required this.isHostedByUser,
  }) : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  Map<String, dynamic>? host; // Variable to store host details
  String error = '';
  bool _isEditing = false;
  bool _isSaving = false; // To show loading indicator while saving

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    fetchProjectDetails();
  }

  Future<void> fetchProjectDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!_isEditing) {
          _titleController.text = data['name'] ?? widget.title;
          _descriptionController.text = data['description'] ?? widget.description;
        }
        setState(() {
          members = List<Map<String, dynamic>>.from(data['members'] ?? []);
          host = data['owner'] != null ? Map<String, dynamic>.from(data['owner']) : null;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load project details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to server: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _saveProjectDetails() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final token = await LocalStorage.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _titleController.text,
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update project: $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving project: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invite Team Member'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter team member\'s email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty) {
                  _inviteTeamMember(context, emailController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Send Invitation'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _inviteTeamMember(BuildContext context, String email) async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/invite_member/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent successfully'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Failed to send invitation';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: const Text('Are you sure you want to delete this project?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteProject();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject() async {
    final token = await LocalStorage.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WorkPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete project: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildMemberChip(Map<String, dynamic> member) {
    final bool isOwner = member['isOwner'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isOwner ? const Color(0xFF255DE1).withOpacity(0.2) : Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOwner ? const Color(0xFF255DE1).withOpacity(0.4) : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOwner ? Icons.star : Icons.person,
            size: 16,
            color: isOwner ? const Color(0xFF255DE1) : Colors.teal[700],
          ),
          const SizedBox(width: 8),
          Text(
            member['full_name'] ?? 'Unknown',
            style: TextStyle(
              fontSize: 14,
              color: isOwner ? const Color(0xFF255DE1) : Colors.teal[800],
              fontWeight: isOwner ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: CustomScaffoldWorkspace(
        selectedPage: 'Work',
        onItemSelected: (String page) {
          if (page == 'Work') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const WorkPage(),
              ),
            );
          }
        },
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Project Title',
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Text(
                              _titleController.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (widget.isHostedByUser)
                      if (_isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.white),
                          tooltip: 'Cancel Edit',
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _titleController.text = widget.title;
                              _descriptionController.text = widget.description;
                            });
                          },
                        ),
                        IconButton(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save, color: Colors.white),
                          tooltip: 'Save Changes',
                          onPressed: _isSaving ? null : _saveProjectDetails,
                        ),
                      ] else
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: 'Edit Project',
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                    if (widget.isHostedByUser)
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        onPressed: () => _showInviteDialog(context),
                      ),
                    if (widget.isHostedByUser)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _showDeleteConfirmationDialog(context),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: ListView(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _isEditing
                              ? TextField(
                                  controller: _descriptionController,
                                  maxLines: null,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.6,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter project description',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  _descriptionController.text.isEmpty
                                      ? 'No description provided.'
                                      : _descriptionController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _descriptionController.text.isEmpty
                                        ? Colors.black38
                                        : Colors.black54,
                                    height: 1.6,
                                  ),
                                ),
                          if (!_isEditing && host != null) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(Icons.star, size: 18, color: Colors.orange[800]),
                                const SizedBox(width: 6),
                                Text(
                                  'Host: ${host!['full_name'] ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),
                          const Text(
                            'Team',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (isLoading)
                            const Center(
                              child: CircularProgressIndicator(),
                            )
                          else if (error.isNotEmpty)
                            Text(
                              error,
                              style: const TextStyle(color: Colors.red),
                            )
                          else
                            Builder(
                              builder: (context) {
                                final actualMembers = members
                                    .where((member) => host == null || member['id'] != host!['id'])
                                    .toList();

                                if (actualMembers.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'No other team members yet.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Team Members',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: actualMembers
                                            .map((member) => _buildMemberChip(member))
                                            .toList(),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Tasks',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ProjectTaskList(
                            projectId: widget.projectId,
                            teamMembers: [if (host != null) host!, ...members], // Pass host and members
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}