// // import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:project/widgets/custom_scaffold.dart'; // Your custom scaffold with sidebar
// // import 'package:project/providers/notes_provider.dart';

// class QuickNotesPage extends StatefulWidget {
//   const QuickNotesPage({Key? key}) : super(key: key);

//   @override
//   _QuickNotesPageState createState() => _QuickNotesPageState();
// }

// class _QuickNotesPageState extends State<QuickNotesPage> {
//   String _selectedPage = 'Quick Notes';
//   String _noteTitle = '';
//   String _noteContent = '';
//   PlatformFile? _selectedImage;
//   PlatformFile? _selectedFile;
//   PlatformFile? _selectedVideo;

//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _contentController = TextEditingController();

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _contentController.dispose();
//     super.dispose();
//   }

//   // Pick an image from the gallery
//   Future<void> _pickImage() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.image);
//     if (result != null && result.files.isNotEmpty) {
//       setState(() {
//         _selectedImage = result.files.first;
//       });
//     }
//   }

//   // Pick any file (e.g., PDF, DOCX)
//   Future<void> _pickFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result != null && result.files.isNotEmpty) {
//       setState(() {
//         _selectedFile = result.files.first;
//       });
//     }
//   }

//   // Pick a video from the gallery
//   Future<void> _pickVideo() async {
//     final result = await FilePicker.platform.pickFiles(type: FileType.video);
//     if (result != null && result.files.isNotEmpty) {
//       setState(() {
//         _selectedVideo = result.files.first;
//       });
//     }
//   }

//   // Save the note using the provider
//   Future<void> _saveNote(NotesProvider notesProvider) async {
//     await notesProvider.addNote(
//       title: _noteTitle,
//       content: _noteContent,
//       image: _selectedImage,
//       file: _selectedFile,
//       video: _selectedVideo,
//     );
//     // Clear input fields after saving
//     setState(() {
//       _noteTitle = '';
//       _noteContent = '';
//       _selectedImage = null;
//       _selectedFile = null;
//       _selectedVideo = null;
//       _titleController.clear();
//       _contentController.clear();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final notesProvider = Provider.of<NotesProvider>(context);

//     return CustomScaffold(
//       selectedPage: _selectedPage,
//       onItemSelected: (page) {
//         setState(() {
//           _selectedPage = page;
//         });
//       },
//       body: Scaffold(
//         appBar: AppBar(
//           title: const Text('Quick Notes'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: () {
//                 _saveNote(notesProvider);
//               },
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               TextField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(
//                   labelText: 'Title',
//                   border: OutlineInputBorder(),
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     _noteTitle = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _contentController,
//                 decoration: const InputDecoration(
//                   labelText: 'Content',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 5,
//                 onChanged: (value) {
//                   setState(() {
//                     _noteContent = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton(
//                     onPressed: _pickImage,
//                     child: const Text('Pick Image'),
//                   ),
//                   ElevatedButton(
//                     onPressed: _pickFile,
//                     child: const Text('Pick File'),
//                   ),
//                   ElevatedButton(
//                     onPressed: _pickVideo,
//                     child: const Text('Pick Video'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 'Selected Image: ${_selectedImage?.name ?? 'None'}',
//                 style: const TextStyle(color: Colors.grey),
//               ),
//               Text(
//                 'Selected File: ${_selectedFile?.name ?? 'None'}',
//                 style: const TextStyle(color: Colors.grey),
//               ),
//               Text(
//                 'Selected Video: ${_selectedVideo?.name ?? 'None'}',
//                 style: const TextStyle(color: Colors.grey),
//               ),
//               const SizedBox(height: 20),
//               // Optionally, display the list of notes (if you want to see them on the page)
//               const Divider(),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: NeverScrollableScrollPhysics(),
//                 itemCount: notesProvider.notes.length,
//                 itemBuilder: (ctx, index) {
//                   final note = notesProvider.notes[index];
//                   return ListTile(
//                     title: Text(note.title),
//                     subtitle: Text(note.content),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


