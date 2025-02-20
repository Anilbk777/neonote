class Note {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? fileUrl;
  final String? videoUrl;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.fileUrl,
    this.videoUrl,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image'],
      fileUrl: json['file'],
      videoUrl: json['video'],
    );
  }
}
