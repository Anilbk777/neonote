class Note {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String? file;
  final String? video;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.file,
    this.video,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      image: json['image'],
      file: json['file'],
      video: json['video'],
    );
  }
}
