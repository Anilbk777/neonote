


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:provider/provider.dart';
// import 'package:project/models/page.dart';
// import 'package:project/providers/pages_provider.dart';
// import 'package:project/widgets/custom_scaffold.dart';

// class ContentPage extends StatefulWidget {
//   final PageModel page;
//   ContentPage({required this.page});

//   @override
//   _ContentPageState createState() => _ContentPageState();
// }

// class _ContentPageState extends State<ContentPage> {
//   late QuillController _quillController;
//   final FocusNode _focusNode = FocusNode();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     Document doc;

//     try {
//       doc = Document.fromJson(jsonDecode(widget.page.content));
//     } catch (e) {
//       doc = Document()..insert(0, widget.page.content);
//     }

//     _quillController = QuillController(
//       document: doc,
//       selection: const TextSelection.collapsed(offset: 0),
//     );
//   }


//   void _openUrl(String url) async {
//   final Uri uri = Uri.parse(url);
//   if (await canLaunchUrl(uri)) {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   } else {
//     // Show error if URL cannot be launched
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Could not open link: $url")),
//     );
//   }


// }


//   @override
//   void dispose() {
//     _quillController.dispose();
//     _focusNode.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // Helper method to get PageModel by title.
//   PageModel getPageModelByTitle(String title) {
//     List<PageModel> pages = Provider.of<PagesProvider>(context, listen: false).pages;
//     return pages.firstWhere(
//       (page) => page.title == title,
//       orElse: () => PageModel(id: 0, title: 'Not Found', content: ''),
//     );
//   }

//   void _saveContent() {
//     // Encode the current document as Delta JSON.
//     String updatedContent = jsonEncode(_quillController.document.toDelta().toJson());
//     Provider.of<PagesProvider>(context, listen: false)
//         .updatePage(widget.page.id, widget.page.title, updatedContent)
//         .then((_) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Content saved")));
//     }).catchError((error) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Error saving content")));
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       selectedPage: widget.page.title,
//       body: Scaffold(
//         appBar: AppBar(
//           title: Text(widget.page.title),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.save),
//               onPressed: _saveContent,
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Display the Quill toolbar.
//               QuillSimpleToolbar(controller: _quillController),
//               const SizedBox(height: 8),
//               // Display the Quill editor.
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () {
//                     final selection = _quillController.selection;
//                     final text = _quillController.document.getPlainText(selection.baseOffset, selection.extentOffset);

//                     // Check if the tapped text is a valid URL
//                     final uri = Uri.tryParse(text);
//                     if (uri != null && uri.hasAbsolutePath) {
//                       _openUrl(text); // Open URL in browser
//                     }
//                   },
//                   child: QuillEditor(
//                     controller: _quillController,
//                     focusNode: _focusNode,
//                     scrollController: _scrollController,
//                     // expands: false,
//                     //  padding: const EdgeInsets.all(1),
//                     config: const QuillEditorConfig(
//                       placeholder: "Enter page content here...",
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       onItemSelected: (String selectedPageTitle) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ContentPage(page: getPageModelByTitle(selectedPageTitle)),
//           ),
//         );
//       },
//     );
//   }
// }


// ===================================================================================================================





import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';
import 'package:project/models/page.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/widgets/custom_scaffold.dart';

class ContentPage extends StatefulWidget {
  final PageModel page;
  ContentPage({required this.page});

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Add a text editing controller for the title
  final TextEditingController _titleController = TextEditingController();
  bool _isEditingTitle = false;


  void _openUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Show error if URL cannot be launched
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not open link: $url")),
    );
  }


}


  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Helper method to get PageModel by title.
  PageModel getPageModelByTitle(String title) {
    List<PageModel> pages = Provider.of<PagesProvider>(context, listen: false).pages;
    return pages.firstWhere(
      (page) => page.title == title,
      orElse: () => PageModel(id: 0, title: 'Not Found', content: ''),
    );
  }

  @override
  void initState() {
    super.initState();
    Document doc;

    try {
      doc = Document.fromJson(jsonDecode(widget.page.content));
    } catch (e) {
      doc = Document()..insert(0, widget.page.content);
    }

    _quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Initialize the title controller with the current page title
    _titleController.text = widget.page.title;
  }

  void _saveContent() {
    // Encode the current document as Delta JSON.
    String updatedContent = jsonEncode(_quillController.document.toDelta().toJson());
    Provider.of<PagesProvider>(context, listen: false)
        .updatePage(widget.page.id, _titleController.text, updatedContent)
        .then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Content saved")));
    }).catchError((error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error saving content")));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: _titleController.text,
      body: Scaffold(
        appBar: AppBar(
          title: _isEditingTitle
            ? TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter page title',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) {
                  setState(() {
                    _isEditingTitle = false;
                  });
                  _saveContent(); // Save the title when done editing
                },
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleController.text,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () {
                      setState(() {
                        _isEditingTitle = true;
                      });
                    },
                  ),
                ],
              ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveContent,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display the Quill toolbar.
              QuillSimpleToolbar(controller: _quillController),
              const SizedBox(height: 8),
              // Display the Quill editor.
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final selection = _quillController.selection;
                    final text = _quillController.document.getPlainText(selection.baseOffset, selection.extentOffset);

                    // Check if the tapped text is a valid URL
                    final uri = Uri.tryParse(text);
                    if (uri != null && uri.hasAbsolutePath) {
                      _openUrl(text); // Open URL in browser
                    }
                  },
                  child: QuillEditor(
                    controller: _quillController,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    // expands: false,
                    //  padding: const EdgeInsets.all(1),
                    config: const QuillEditorConfig(
                      placeholder: "Enter page content here...",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onItemSelected: (String selectedPageTitle) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentPage(page: getPageModelByTitle(selectedPageTitle)),
          ),
        );
      },
    );
  }
}
