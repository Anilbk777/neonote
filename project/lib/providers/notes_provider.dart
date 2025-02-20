// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:project/models/note.dart' as noteModel;
// import 'package:project/services/api_service.dart';

// class NotesProvider with ChangeNotifier {
//   final ApiService _apiService = ApiService();
//   List<noteModel.Note> _notes = [];
//   String _token = '';
//   Timer? _pollingTimer;

//   List<noteModel.Note> get notes => _notes;

//   void setToken(String token) {
//     _token = token;
//     fetchNotes();
//     _startPolling();
//   }

//   Future<void> fetchNotes() async {
//     try {
//       _notes = await _apiService.fetchNotes(_token);
//       notifyListeners();
//     } catch (e) {
//       if (kDebugMode) {
//         print("Error fetching notes: $e");
//       }
//     }
//   }

//   void _startPolling() {
//     _pollingTimer?.cancel();
//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
//       fetchNotes();
//     });
//   }

//   void stopPolling() {
//     _pollingTimer?.cancel();
//   }

//   @override
//   void dispose() {
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> addNote({
//     required String title,
//     required String content,
//     PlatformFile? image,
//     PlatformFile? file,
//     PlatformFile? video,
//   }) async {
//     try {
//       await _apiService.createNote(
//         token: _token,
//         title: title,
//         content: content,
//         image: image,
//         file: file,
//         video: video,
//       );
//       fetchNotes(); // Refresh the notes list after adding a new note
//     } catch (e) {
//       if (kDebugMode) {
//         print("Error adding note: $e");
//       }
//     }
//   }
// }
