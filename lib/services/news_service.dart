import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  // Replace with your Render deployment URL after deploying
  static const String _baseUrl = 'https://your-render-app.onrender.com/api';

  Future<List<NewsArticle>> getStartupNews() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/startup-news'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle.fromJson(article)).toList();
      } else {
        return _getDummyNews();
      }
    } catch (e) {
      return _getDummyNews();
    }
  }

  Future<List<NewsArticle>> getTechNews() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tech-news'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle.fromJson(article)).toList();
      } else {
        return _getDummyNews();
      }
    } catch (e) {
      return _getDummyNews();
    }
  }

  List<NewsArticle> _getDummyNews() {
    return [
      NewsArticle(
        title: 'AI Startups Raise Record Funding in Q1 2024',
        description: 'Artificial intelligence startups have secured unprecedented funding in the first quarter of 2024.',
        url: 'https://example.com/ai-funding',
        urlToImage: 'https://picsum.photos/800/400',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'TechCrunch',
      ),
      NewsArticle(
        title: 'New Tech Hub Opens in Silicon Valley',
        description: 'A new technology innovation center has opened its doors in the heart of Silicon Valley.',
        url: 'https://example.com/tech-hub',
        urlToImage: 'https://picsum.photos/800/401',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
        source: 'Tech Insider',
      ),
      NewsArticle(
        title: 'Startup Ecosystem Grows in Emerging Markets',
        description: 'Emerging markets are seeing rapid growth in their startup ecosystems.',
        url: 'https://example.com/emerging-markets',
        urlToImage: 'https://picsum.photos/800/402',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
        source: 'Startup Weekly',
      ),
    ];
  }
}

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      source: json['source']['name'] ?? '',
    );
  }
} 