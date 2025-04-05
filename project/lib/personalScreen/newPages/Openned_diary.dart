import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart';

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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();


  late DateTime _selectedDate = DateTime.now();
  bool _isReadOnly = false;
  String _selectedTemplate = 'Default';
  String _selectedPage = 'Diary';
  
  // Added color variables
   Color _backgroundColor = const Color(0xFFFFFFFF);
  Color _textColor = const Color(0xFF060606);
  
  // Added mood emoji variable
  String _selectedMood = '';

  
  // Emojis to describe the day
  final Map<String, String> _moodEmojis = {
   'Happy': '😊',
    'Sad': '😢',
    'Excited': '🤩',
    'Tired': '😴',
    'Anxious': '😰',
    // 'Peaceful': '😌',
    // 'Grateful': '🙏',
    // 'Angry': '😠',
    // 'Love': '❤️',
    // 'Sick': '🤒',
  };

  // Templates options
  final List<String> _templates = [
    'Default',
    'Gratitude Journal',
    'Daily Reflection',
    'Travel Log',
    'Dream Journal'
  ];

  // Template content presets
  final Map<String, String> _templateContents = {
    'Default': '',
    'Gratitude Journal': 'Today I am grateful for:\n1. \n2. \n3. \n\nOne positive thing that happened today: ',
    'Daily Reflection': 'Morning thoughts:\n\nMain achievements today:\n\nChallenges faced:\n\nLessons learned:',
    'Travel Log': 'Location: \nWeather: \nPlaces visited: \n\nHighlights: \n\nFood tried: \n\nMemories:',
    'Dream Journal': 'Dream summary: \n\nKey symbols: \n\nEmotions: \n\nPossible interpretations:'
  };

  // Added color palette options
   final List<Color> _backgroundColorOptions = [
    const Color(0xFFFCF7F7),
    const Color(0xFFF4F4D5),
    const Color(0xFFD2E3F2),
    const Color(0xFFF9D5E1),
    const Color(0xFFEBFDEB),
    const Color(0xFFFCF7EC),
    const Color(0xFFDADAFB),
    const Color(0xFFFEF9C9),
    const Color(0xFF72F494),
    const Color(0xFF608BF8),
    const Color(0xFFF170DB),
    const Color(0xFFEEA39A),
    const Color(0xFF9EF3A5),
    const Color(0xFFE72DE4),
    const Color(0xFFB041EC),
  ];

  final List<Color> _textColorOptions = [
    const Color(0xFF000000),
    const Color(0xFF24D689),
    const Color(0xFF1B5E20),
    const Color(0xFF004D40),
    const Color(0xFF37474F),
    const Color(0xFF565BF2),
    const Color(0xFF0980B3),
    const Color(0xFF1A227C),
    const Color(0xFFC734EF),
    const Color(0xFF5B0255),
    const Color(0xFF4D1592),
    const Color(0xFF50352F),
    const Color(0xFF52050C),
    const Color(0xFF83340A),
    const Color(0xFF7C442B),
    const Color(0xFFF55968),
    const Color(0xFFE627A0),
    const Color(0xFFF4C575),
    const Color(0xFFF90223),
  ];

    @override
  void initState() {
    super.initState();
    _initializeData();
  }
 void _initializeData() {
  // Set default values
  setState(() {
    _selectedDate = DateTime.now();

    // Initialize colors with default values
    _backgroundColor = const Color(0xFFFFFFFF); // Default to white
    _textColor = const Color(0xFF000000); // Default to black

    // Check if initialData is not null
    if (widget.initialData != null) {
      // Handle background color
      if (widget.initialData!['backgroundColor'] != null) {
        _backgroundColor = Color(widget.initialData!['backgroundColor']);
      }

      if (widget.initialData!['textColor'] != null) {
        _textColor = Color(widget.initialData!['textColor']);
      }

      // Load other initial data
      _titleController.text = widget.initialData!['title'] ?? '';
      _contentController.text = widget.initialData!['content'] ?? '';
      _selectedDate = DateTime.parse(widget.initialData!['date']);
      _selectedMood = widget.initialData!['mood'] ?? '';

      }
    
  }
  );
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
  
  // New method to show mood picker
  void _showMoodPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How are you feeling today?'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
        content: Text('Background color updated'),
        duration: const Duration(seconds: 1),
        backgroundColor: color,
      ),
    );
  }

  // Method to change text color
  void _changeTextColor(Color color) {
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
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      border: Border.all(color: const Color.fromARGB(255, 161, 161, 161)),
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
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      border: Border.all(color: const Color.fromARGB(255, 161, 161, 161)),
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
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
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

  void _saveDiary() {
    // Return the diary title to the previous page along with all data
    Map<String, dynamic> diaryData = {
      'title': _titleController.text.isNotEmpty 
          ? _titleController.text 
          : DateFormat('MMM d, yyyy').format(_selectedDate),
       'backgroundColor': _backgroundColor.value, // Store color as integer
       'textColor': _textColor.value, 
      'content': _contentController.text,
      'date': _selectedDate.toIso8601String(), 
      'mood': _selectedMood,
      // 'images': _images.map((file) => file.path).toList(),
    };
    
    Navigator.pop(context, diaryData);
  }

  @override
  Widget build(BuildContext context) {
    // Main diary content widget
    Widget diaryContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top app bar with actions
        AppBar(
          title: const Text('Write Today'),
          backgroundColor: const Color.fromARGB(255, 37, 93, 225),
          elevation: 0,
          actions: [
            // Mood button
            IconButton(
              icon: _selectedMood.isNotEmpty
                  ? Text(
                      _moodEmojis[_selectedMood] ?? '🙂',
                      style: const TextStyle(fontSize: 24),
                    )
                  : const Icon(Icons.emoji_emotions_outlined),
              onPressed: _showMoodPicker,
              tooltip: 'Set your mood',
            ),
            
        
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isReadOnly ? null : _saveDiary,
              tooltip: 'Save entry',
            ),
            
            // Three dot menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String choice) {
                if (choice == 'Templates') {
                  // Show template selection dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Select Template'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _templates.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Text(_templates[index]),
                                onTap: () {
                                  _changeTemplate(_templates[index]);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                } else if (choice == 'Preview') {
                  _toggleReadOnlyMode();
                } else if (choice == 'BackgroundColor') {
                  _showBackgroundColorPicker();
                } else if (choice == 'TextColor') {
                  _showTextColorPicker();
                } else if (choice == 'Mood') 
                  _showMoodPicker();
                // } else if (choice == 'AddImage') {
                //   _pickImage();
                // } else if (choice == 'ViewImages') {
                //   _viewImages();
                // }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'Templates',
                  child: ListTile(
                    leading: Icon(Icons.article),
                    title: Text('Select Template'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'BackgroundColor',
                  child: ListTile(
                    leading: Icon(Icons.format_color_fill),
                    title: Text('Change Background Color'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'TextColor',
                  child: ListTile(
                    leading: Icon(Icons.format_color_text),
                    title: Text('Change Text Color'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Mood',
                  child: ListTile(
                    leading: Icon(Icons.emoji_emotions),
                    title: Text('Set Mood'),
                  ),
                ),

                PopupMenuItem<String>(
                  value: 'Preview',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Preview Mode'),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Date section with picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 254, 254),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 169, 168, 168).withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Content area with text color
                  Expanded(
                    child: TextField(
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Status bar at bottom showing selected options
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color.fromARGB(255, 244, 243, 243),
          child: Row(
            children: [
              Text(
                'Template: $_selectedTemplate',
                style: TextStyle(
                  color: const Color.fromARGB(255, 37, 93, 225),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedMood.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Mood: ${_moodEmojis[_selectedMood]}',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 37, 93, 225),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const Spacer(),
           
                  Container(
                    width: 16,
                    height: 16,
                    margin: EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      border: Border.all(color: const Color.fromARGB(255, 163, 162, 162)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _textColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    _isReadOnly ? 'Preview Mode' : 'Edit Mode',
                    style: TextStyle(
                      color: _isReadOnly ? const Color.fromARGB(255, 253, 160, 1) : const Color.fromARGB(255, 64, 159, 68),
                      fontWeight: FontWeight.w500,
                    ),
            
              ),
            ],
          ),
        ),
      ],
    );

    return CustomScaffold(
      selectedPage: _selectedPage,
      onItemSelected: (String page) {
        setState(() {
          _selectedPage = page;
        });
      },
      body: diaryContent,
      floatingActionButton: null, 
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}



