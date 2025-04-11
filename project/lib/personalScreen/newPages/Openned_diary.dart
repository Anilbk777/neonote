import 'dart:io';
import 'dart:convert';
import 'dart:math' show min;
import 'package:http/http.dart' as http;
import 'package:project/services/local_storage.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/services/diary_service.dart';

class NewDiaryPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const NewDiaryPage({
    Key? key,
    this.initialData,
  }) : super(key: key);

  @override
  _NewDiaryPageState createState() => _NewDiaryPageState();
}

class _NewDiaryPageState extends State<NewDiaryPage> {
  // Global key for the scaffold messenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  late DateTime _selectedDate = DateTime.now();
  bool _isReadOnly = false;
  String _selectedTemplate = 'Default';
  String _selectedPage = 'Diary';

  // Added color variables
  Color _backgroundColor = const Color(0xFFFFFFFF); // Default to white
  Color _textColor = const Color(0xFF000000); // Default to black

  // Define mood emojis
  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Excited': '🤩',
    'Tired': '😴',
    'Anxious': '😰',
  };

  // Define template contents
  final Map<String, String> _templateContents = {
    'Default': '',
    'Gratitude': 'Today, I am grateful for...',
    'Reflection': 'Today I learned...\nI felt...\nTomorrow I will...',
    'Goals': 'My goals for today are:\n1.\n2.\n3.',
  };

  // Define color options
  final List<Color> _backgroundColorOptions = [
    const Color(0xFFFFFFFF), // White
    const Color(0xFFF5F5F5), // Light Gray
    const Color(0xFFFFF8E1), // Light Yellow
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFF3E5F5), // Light Purple
    const Color(0xFFFFEBEE), // Light Red
    const Color(0xFFFCE4EC), // Light Pink
  ];

  final List<Color> _textColorOptions = [
    const Color(0xFF000000), // Black
    const Color(0xFF424242), // Dark Gray
    const Color(0xFF1976D2), // Blue
    const Color(0xFF388E3C), // Green
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFFD32F2F), // Red
    const Color(0xFFFF6F00), // Orange
    const Color(0xFF5D4037), // Brown
  ];

  String _selectedMood = '';

  @override
  void initState() {
    super.initState();
    print('NewDiaryPage initState called');
    print('Initial widget.initialData: ${widget.initialData}');
    _initializeData();

    // Add a delayed check to see if the controllers have text after initialization
    Future.delayed(Duration(milliseconds: 100), () {
      print('Delayed check - Title controller text: "${_titleController.text}"');
      print('Delayed check - Content controller text: "${_contentController.text}"');
    });
  }

  void _initializeData() {
    // Set default values
    setState(() {
      _selectedDate = DateTime.now();

      // Initialize title and content with empty values
      _titleController.text = '';
      _contentController.text = '';

      // Initialize colors with default values
      _backgroundColor = const Color(0xFFFFFFFF); // Default to white
      _textColor = const Color(0xFF000000); // Default to black

      // Check if initialData is not null
      if (widget.initialData != null) {
        print('Initializing with data: ${widget.initialData}');

        // Handle background color - try both naming conventions
        try {
          print('Text color before setting: ${_textColor.value.toRadixString(16)}');

          if (widget.initialData!['text_color'] != null) {
            int txtColor = widget.initialData!['text_color'];
            print('Raw text_color value: $txtColor (hex: ${txtColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (txtColor == 0) {
              txtColor = 0xFF000000; // Default to black with alpha
              print('Text color was 0, defaulting to black with alpha');
            } else if ((txtColor & 0xFF000000) == 0) {
              txtColor = txtColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to text color: ${txtColor.toRadixString(16)}');
            }

            _textColor = Color(txtColor);
            print('Set text color from text_color: $txtColor (hex: ${txtColor.toRadixString(16)})');
          } else if (widget.initialData!['textColor'] != null) {
            int txtColor = widget.initialData!['textColor'];
            print('Raw textColor value: $txtColor (hex: ${txtColor.toRadixString(16)})');

            // Ensure the color has an alpha channel
            if (txtColor == 0) {
              txtColor = 0xFF000000; // Default to black with alpha
              print('Text color was 0, defaulting to black with alpha');
            } else if ((txtColor & 0xFF000000) == 0) {
              txtColor = txtColor | 0xFF000000; // Add alpha channel if missing
              print('Added alpha channel to text color: ${txtColor.toRadixString(16)}');
            }

            _textColor = Color(txtColor);
            print('Set text color from textColor: $txtColor (hex: ${txtColor.toRadixString(16)})');
          } else {
            // If no text color is provided, default to black
            _textColor = const Color(0xFF000000);
            print('No text color provided, defaulting to black');
          }

          print('Final text color: ${_textColor.value.toRadixString(16)}');
        } catch (e) {
          print('Error setting text color: $e');
          _textColor = const Color(0xFF000000); // Default to black
          print('Set default text color due to error: ${_textColor.value.toRadixString(16)}');
        }

        // Load other initial data
        final title = widget.initialData!['title'];
        final content = widget.initialData!['content'];
        print('Initializing with title: "$title", content: "$content"');

        // Set title and content with explicit toString() conversion and fallbacks
        if (title != null) {
          final titleStr = title.toString();
          print('Setting title controller text to: "$titleStr"');
          _titleController.text = titleStr;

          // Force update the controller
          _titleController.value = TextEditingValue(
            text: titleStr,
            selection: TextSelection.collapsed(offset: titleStr.length),
          );
        } else {
          print('Title was null, using default title');
          _titleController.text = 'New Diary Entry';
        }

        if (content != null) {
          final contentStr = content.toString();
          print('Setting content controller text to: "${contentStr.substring(0, min(20, contentStr.length))}..."');
          _contentController.text = contentStr;

          // Force update the controller
          _contentController.value = TextEditingValue(
            text: contentStr,
            selection: TextSelection.collapsed(offset: contentStr.length),
          );
        } else {
          print('Content was null, using empty string');
          _contentController.text = '';
        }

        _selectedDate = DateTime.parse(widget.initialData!['date']);
        _selectedMood = widget.initialData!['mood'] ?? '';
        _selectedTemplate = widget.initialData!['template'] ?? 'Default';
      }
    });
  }

  void _changeTemplate(String template) {
    setState(() {
      _selectedTemplate = template;
      _contentController.text = _templateContents[template] ?? '';
    });
  }

  void _toggleReadOnlyMode() {
    setState(() {
      _isReadOnly = !_isReadOnly;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isReadOnly ? 'Preview mode enabled' : 'Edit mode enabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // New method to set mood emoji
  void _setMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mood set to $mood ${_moodEmojis[mood]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Method to show mood picker
  void _showMoodPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Mood'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: _moodEmojis.entries.map((entry) {
                return ListTile(
                  leading: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(entry.key),
                  onTap: () {
                    _setMood(entry.key);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Method to change background color
  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          'Background color updated',
          style: TextStyle(color: _textColor),
        ),
        backgroundColor: color,
      ),
    );
  }

  // Method to change text color
  void _changeTextColor(Color color) {
    // Ensure the color is not too light (close to white)
    if ((color.value & 0xFFFFFF) > 0xF0F0F0) {
      print('Selected text color is too light, using black instead');
      color = const Color(0xFF000000); // Use black instead
    }

    print('Changing text color to: ${color.value.toRadixString(16)}');

    setState(() {
      _textColor = color;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: _backgroundColor,
        content: Text(
          'Text color updated',
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  // Method to show background color picker
  void _showBackgroundColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Background Color'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _backgroundColorOptions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _changeBackgroundColor(_backgroundColorOptions[index]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _backgroundColorOptions[index],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Method to show text color picker
  void _showTextColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Text Color'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _textColorOptions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _changeTextColor(_textColorOptions[index]);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _textColorOptions[index],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 37, 93, 225),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 37, 93, 225),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Method to update an existing diary entry
  void _updateSaveDiary() async {
    try {
      if (widget.initialData == null || widget.initialData!['id'] == null) {
        print('Cannot update: No ID found in initialData');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot update: No diary ID found')),
        );
        return;
      }

      final diaryService = DiaryService();
      final id = widget.initialData!['id'];

      // Get title and content from controllers
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      print('Updating diary with title: "$title", length: ${title.length}');
      print('Updating diary with content: "$content", length: ${content.length}');

if (title.isEmpty || content.isEmpty) {
  _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  _scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Please enter both title and content before updating.')),
  );
  return;
}


      print('Updating diary entry with ID: $id');
      print('Title: "$title", Content: "$content"');

      // Ensure color values are never null or zero
      final bgColor = _backgroundColor.value != 0 ? _backgroundColor.value : 0xFFFFFFFF; // Default to white

      // For text color, ensure it's black if it's 0 or very close to white
      int txtColor;
      if (_textColor.value == 0) {
        txtColor = 0xFF000000; // Default to black with alpha
        print('Text color was 0, using black with alpha: ${txtColor.toRadixString(16)}');
      } else {
        txtColor = _textColor.value;

        // If the color is too light (close to white), use black instead
        if ((txtColor & 0xFFFFFF) > 0xF0F0F0) {
          txtColor = 0xFF000000; // Black with alpha
          print('Text color was too light, using black: ${txtColor.toRadixString(16)}');
        }
      }

      print('Final bgColor: ${bgColor.toRadixString(16)}');
      print('Final txtColor: ${txtColor.toRadixString(16)}');

      // Create a diary entry with the ID included
      final diary = DiaryEntry(
        id: id,
        title: title,
        content: content,
        date: _selectedDate,
        mood: _selectedMood.isNotEmpty ? _selectedMood : '', // Send an empty string if no mood is selected
        backgroundColor: bgColor,
        textColor: txtColor,
        template: _selectedTemplate,
        // Include any other fields from the original entry
        images: widget.initialData!['images'] != null ?
          (widget.initialData!['images'] as List).map((img) =>
            DiaryImage(id: img['id'], imageUrl: img['image'])).toList() : [],
      );

      print('Updating diary with data: ${diary.toJson()}');

      // Update the existing diary entry
      final updatedDiary = await diaryService.updateEntry(id, diary);
      print('Diary updated with ID: ${updatedDiary.id}');

      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry updated successfully.')),
      );

      // Return to the previous screen with the updated diary data
      Navigator.pop(context, updatedDiary.toJson());
    } catch (e) {
      print('Error updating diary: $e');
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error updating diary: $e')),
      );
    }
  }

  // Method to delete a diary entry
  void _deleteDiary() async {
    try {
      if (widget.initialData == null || widget.initialData!['id'] == null) {
        print('Cannot delete: No ID found in initialData');
        _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Cannot delete: No diary ID found')),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Diary Entry'),
            content: const Text('Are you sure you want to delete this diary entry?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        print('Deletion cancelled by user');
        return;
      }

      final diaryService = DiaryService();
      final id = widget.initialData!['id'];
      print('Deleting diary entry with ID: $id');

      await diaryService.deleteEntry(id);
      print('Diary entry deleted successfully');

      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry deleted successfully')),
      );

      // Return to the previous screen with null to indicate deletion
      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      print('Error deleting diary: $e');
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error deleting diary: $e')),
      );
    }
  }

  // Method to save a new diary entry
  void _saveDiary() async {
    try {
      final diaryService = DiaryService();
      // Ensure color values are never null or zero
      final bgColor = _backgroundColor.value != 0 ? _backgroundColor.value : 0xFFFFFFFF; // Default to white

      // For text color, ensure it's black if it's 0 or very close to white
      int txtColor;
      if (_textColor.value == 0) {
        txtColor = 0xFF000000; // Default to black with alpha
        print('Text color was 0, using black with alpha: ${txtColor.toRadixString(16)}');
      } else {
        txtColor = _textColor.value;

        // If the color is too light (close to white), use black instead
        if ((txtColor & 0xFFFFFF) > 0xF0F0F0) {
          txtColor = 0xFF000000; // Black with alpha
          print('Text color was too light, using black: ${txtColor.toRadixString(16)}');
        }
      }

      print('Final bgColor: ${bgColor.toRadixString(16)}');
      print('Final txtColor: ${txtColor.toRadixString(16)}');

      // Get title and content from controllers
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      print('Saving diary with title: "$title", length: ${title.length}');
      print('Saving diary with content: "$content", length: ${content.length}');

      // Check if title or content is empty before creating the DiaryEntry object
if (title.isEmpty || content.isEmpty) {
  // Clear any existing snackbars before showing a new one
  _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  _scaffoldMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Please enter both title and content before saving.')),
  );
  return;
}


      final diary = DiaryEntry(
        title: title,
        content: content,
        date: _selectedDate,
        mood: _selectedMood.isNotEmpty ? _selectedMood : '', // Send an empty string if no mood is selected
        backgroundColor: bgColor,
        textColor: txtColor,
        template: _selectedTemplate,
      );

      print('Saving diary: ${diary.toJson()}');
      print('JSON payload: ${json.encode(diary.toJson())}');

      // Create new entry
      print('Creating new diary entry');
      await diaryService.createEntry(diary);
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Diary entry created successfully.')),
      );

      Navigator.pop(context, diary.toJson());
    } catch (e) {
      print('Error saving diary: $e'); // Log the error
      // Clear any existing snackbars before showing a new one
      _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error saving diary: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug the controller values in build
    print('Build method - Title controller text: "${_titleController.text}"');
    print('Build method - Content controller text: "${_contentController.text}"');

    // Main diary content widget
    Widget diaryContent = Column(
      children: [
        // Top bar with date, mood, and actions
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(255, 230, 230, 230),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Date picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Row(
                  children: [
                    Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 37, 93, 225),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today,
                      color: Color.fromARGB(255, 37, 93, 225),
                      size: 18,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Show selected mood if any
              if (_selectedMood.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 251, 251, 251),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color.fromARGB(255, 224, 223, 223)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _moodEmojis[_selectedMood] ?? '🙂',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedMood,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Title and content area with background color
        Expanded(
          child: Container(
            color: _backgroundColor, // Apply the selected background color
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field with text color
                  TextField(
                    key: const Key('titleField'),
                    controller: _titleController,
                    readOnly: _isReadOnly,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textColor, // Apply the selected text color
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onChanged: (value) {
                      print('Title text changed to: "$value"');
                    },
                  ),
                  const SizedBox(height: 16),

                  // Content area with text color
                  Expanded(
                    child: TextField(
                      key: const Key('contentField'),
                      controller: _contentController,
                      readOnly: _isReadOnly,
                      maxLines: null,
                      expands: true,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: _textColor, // Apply the selected text color
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                      ),
                      onChanged: (value) {
                        print('Content text changed to: "${value.substring(0, min(20, value.length))}..."');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom toolbar with formatting options
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color.fromARGB(255, 244, 243, 243),
          child: Row(
            children: [
              // Template info
              Text(
                'Template: $_selectedTemplate',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              // Show mood if selected
              if (_selectedMood.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    'Mood: ${_moodEmojis[_selectedMood]}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),

              // Background color indicator
              Container(
                margin: const EdgeInsets.only(right: 4),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  border: Border.all(color: const Color.fromARGB(255, 163, 162, 162)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Text color indicator
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _textColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Edit/Preview mode indicator
              Text(
                _isReadOnly ? 'Preview Mode' : 'Edit Mode',
                style: TextStyle(
                  fontSize: 12,
                  color: _isReadOnly ? const Color.fromARGB(255, 253, 160, 1) : const Color.fromARGB(255, 64, 159, 68),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: CustomScaffold(
      selectedPage: _selectedPage,
      onItemSelected: (String page) {
        setState(() {
          _selectedPage = page;
        });
      },
      body: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.auto_stories, size: 24, color: Colors.white),
              SizedBox(width: 8),
              Text('Diary'),
            ],
          ),
         actions: [
  // Show only the appropriate button based on whether we're editing or creating
  IconButton(
    icon: widget.initialData != null && widget.initialData!['id'] != null
      ? const Icon(Icons.update)
      : const Icon(Icons.save),
    onPressed: _isReadOnly ? null : (widget.initialData != null && widget.initialData!['id'] != null
      ? _updateSaveDiary
      : _saveDiary),
    tooltip: widget.initialData != null && widget.initialData!['id'] != null
      ? 'Update Diary'
      : 'Save New Diary',
  ),
  // Show delete button only when editing an existing entry
  if (widget.initialData != null && widget.initialData!['id'] != null)
    IconButton(
      icon: const Icon(Icons.delete),
      onPressed: _isReadOnly ? null : _deleteDiary,
      tooltip: 'Delete Diary',
    ),
],

        ),
        body: diaryContent,
      ),
      floatingActionButton: null,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
