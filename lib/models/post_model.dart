class PostModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final String date;
  final String category;
  final int likes;
  final List<String> comments;
  final String imageUrl;
  final List<String> tags;
  bool bookmarked;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.category,
    required this.likes,
    required this.comments,
    required this.imageUrl,
    required this.tags,
    this.bookmarked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        author: json['author'],
        date: json['date'],
        category: json['category'],
        likes: json['likes'],
        comments: List<String>.from(json['comments'] ?? []),
        imageUrl: json['imageUrl'],
        tags: List<String>.from(json['tags'] ?? []),
        bookmarked: json['bookmarked'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'date': date,
        'category': category,
        'likes': likes,
        'comments': comments,
        'imageUrl': imageUrl,
        'tags': tags,
        'bookmarked': bookmarked,
      };
} 