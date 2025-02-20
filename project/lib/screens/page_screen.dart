// screens/page_screen.dart
import 'package:flutter/material.dart';
import 'package:project/models/page.dart';
// import 'models/page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class PageScreen extends StatefulWidget {
  final int pageId;
  final String pageTitle;

  PageScreen({required this.pageId, required this.pageTitle});

  @override
  _PageScreenState createState() => _PageScreenState();
}

class _PageScreenState extends State<PageScreen> {
  List<PageContent> contentList = [];

  void _addTextContent() {
    setState(() {
      contentList.add(PageContent(
          id: contentList.length + 1,
          type: 'text',
          content: 'New Text',
          filePath: ''));
    });
  }

  void _addImageContent() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        contentList.add(PageContent(
            id: contentList.length + 1,
            type: 'image',
            content: 'Image Content',
            filePath: pickedFile.path));
      });
    }
  }

  void _addPdfContent() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() {
        contentList.add(PageContent(
            id: contentList.length + 1,
            type: 'pdf',
            content: 'PDF Content',
            filePath: result.files.single.path!));
      });
    }
  }

  void _addVideoContent() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['mp4', 'mov']);
    if (result != null) {
      setState(() {
        contentList.add(PageContent(
            id: contentList.length + 1,
            type: 'video',
            content: 'Video Content',
            filePath: result.files.single.path!));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pageTitle)),
      body: ListView.builder(
        itemCount: contentList.length,
        itemBuilder: (context, index) {
          final content = contentList[index];
          return ListTile(
            title: content.type == 'text'
                ? Text(content.content)
                : content.type == 'image'
                    ? Image.file(File(content.filePath))
                    : content.type == 'pdf'
                        ? Icon(Icons.picture_as_pdf)
                        : content.type == 'video'
                            ? Icon(Icons.video_library)
                            : Container(),
            subtitle: content.type == 'text' ? null : Text(content.filePath),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addTextContent,
            child: Icon(Icons.text_fields),
            tooltip: 'Add Text',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _addImageContent,
            child: Icon(Icons.image),
            tooltip: 'Add Image',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _addPdfContent,
            child: Icon(Icons.picture_as_pdf),
            tooltip: 'Add PDF',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _addVideoContent,
            child: Icon(Icons.video_library),
            tooltip: 'Add Video',
          ),
        ],
      ),
    );
  }
}
