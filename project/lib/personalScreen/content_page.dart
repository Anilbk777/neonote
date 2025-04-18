


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
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_quill/src/common/structs/horizontal_spacing.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _showToolbar = true; // Show toolbar by default

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Fixed image size for embedded images
  final double _fixedImageWidth = 300.0;
  final double _fixedImageHeight = 200.0;


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

  // Add a listener to the QuillController to handle formatting changes
  void _setupQuillController() {
    // Add a listener to the controller to handle formatting changes
    _quillController.addListener(() {
      // This ensures that when a formatting option is selected,
      // it will be applied to new text that is typed
      setState(() {
        // Force a rebuild to apply the current formatting
      });
    });
  }

  // Method to pick and embed an image
  Future<void> _pickAndEmbedImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedImage == null) {
        print('No image selected');
        return;
      }

      String imageSource;

      if (kIsWeb) {
        // For web, we need to use a data URL
        final bytes = await pickedImage.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = pickedImage.mimeType ?? 'image/jpeg';
        imageSource = 'data:$mimeType;base64,$base64Image';
        print('Web image source: data URL (truncated for brevity)');
      } else {
        // For mobile, we can use the file path
        imageSource = pickedImage.path;
        print('Mobile image source: $imageSource');
      }

      // Create a custom embed for the image with fixed size
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;

      // Insert the image at the current cursor position
      _quillController.replaceText(
        index,
        length,
        BlockEmbed.image(imageSource),
        null, // TextSelection parameter should be null or a valid TextSelection object
      );

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image added successfully')),
      );
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding image: $e')),
      );
    }
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
      keepStyleOnNewLine: true, // Keep formatting when creating new lines
    );

    // Setup the QuillController to handle formatting changes
    _setupQuillController();

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
            // Toggle toolbar button
            IconButton(
              icon: Icon(_showToolbar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() {
                  _showToolbar = !_showToolbar;
                });
              },
              tooltip: _showToolbar ? 'Hide formatting' : 'Show formatting',
            ),

            // Save button
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveContent,
              tooltip: 'Save Content',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Display the Quill toolbar if showToolbar is true
              if (_showToolbar)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: QuillSimpleToolbarConfig(
                      // Enable all formatting options for MS Word-like experience
                      multiRowsDisplay: true,
                      showFontFamily: true,
                      showFontSize: true,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: true,
                      showInlineCode: true,
                      showColorButton: true,
                      showBackgroundColorButton: true,
                      showClearFormat: true,
                      showAlignmentButtons: true,
                      showHeaderStyle: true,
                      showListNumbers: true,
                      showListBullets: true,
                      showListCheck: true,
                      showCodeBlock: true,
                      showQuote: true,
                      showIndent: true,
                      showLink: true,
                      // Enable image embedding in the toolbar
                      embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                      // Custom button options to ensure formatting is applied to new text
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          afterButtonPressed: () {
                            // Force focus on the editor after a button is pressed
                            _focusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
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
                    config: QuillEditorConfig(
                      placeholder: "Enter page content here...",
                      padding: const EdgeInsets.all(0),
                      // Set autoFocus to true to ensure the editor receives focus
                      // This helps with applying formatting to new text
                      autoFocus: true,
                      expands: true,
                      scrollable: true,
                      keyboardAppearance: Brightness.light,
                      enableInteractiveSelection: true,
                      // Enable retaining formatting when typing new text
                      // This makes the toolbar buttons work for new text
                      // Configure embedBuilders to handle images with fixed size
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(
                        imageEmbedConfig: QuillEditorImageEmbedConfig(
                          imageProviderBuilder: (context, imageSource) {
                            if (imageSource.startsWith('http') && !imageSource.startsWith('blob:http')) {
                              // Regular network image (not blob)
                              return NetworkImage(imageSource);
                            } else if (imageSource.startsWith('data:')) {
                              // Data URL (for web)
                              return MemoryImage(Uri.parse(imageSource).data!.contentAsBytes());
                            } else if (imageSource.startsWith('blob:')) {
                              // Blob URL (for web)
                              print('Blob URL detected: $imageSource');
                              try {
                                // Attempt to load the placeholder asset
                                return const AssetImage('assets/images/image_placeholder.png');
                              } catch (e) {
                                print('Error loading placeholder image: $e');
                                // Fallback to a default color or another placeholder
                                return MemoryImage(Uint8List(0)); // Empty image
                              }
                            } else if (kIsWeb) {
                              // For web, we can't use FileImage, so we'll use an asset image as a fallback
                              print('Warning: Unsupported image source on web: $imageSource');
                              return const AssetImage('assets/images/image_placeholder.png');
                            } else if (imageSource.startsWith('file:')) {
                              // File URI (for mobile)
                              return FileImage(File(imageSource.replaceFirst('file:', '')));
                            } else {
                              // Local file path (for mobile)
                              return FileImage(File(imageSource));
                            }
                          },
                          // Callback when an image is removed
                          onImageRemovedCallback: (imageSource) async {
                            print('Image removed: $imageSource');
                            return; // Return a completed Future<void>
                          },
                        ),
                      ),
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
