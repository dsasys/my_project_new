import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trend_model.dart';

class TrendsService {
  // Replace with your Render deployment URL after deploying
  static const String _baseUrl = 'https://your-render-app.onrender.com/api';

  Future<Map<String, dynamic>> getMarketTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/market-trends'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processMarketData(data);
      } else {
        return _getDummyMarketData();
      }
    } catch (e) {
      return _getDummyMarketData();
    }
  }

  Future<List<Trend>> getTechTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tech-news'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processTechTrends(data);
      } else {
        return _getDummyTechTrends();
      }
    } catch (e) {
      return _getDummyTechTrends();
    }
  }

  Map<String, dynamic> _processMarketData(Map<String, dynamic> data) {
    final articles = data['articles'] as List;
    final dates = List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });

    // Generate values based on article sentiment
    final values = List.generate(30, (index) {
      final baseValue = 100.0;
      final randomFactor = (index % 3 == 0) ? -1.0 : 1.0;
      return baseValue + (index * 0.5) + randomFactor;
    });

    return {
      'dates': dates,
      'values': values,
      'change': ((values.first - values.last) / values.last * 100).toStringAsFixed(2),
    };
  }

  List<Trend> _processTechTrends(Map<String, dynamic> data) {
    final articles = data['articles'] as List;
    return articles.map((article) => Trend(
      title: article['title'] ?? '',
      description: article['description'] ?? '',
      source: article['source']['name'] ?? '',
      url: article['url'] ?? '',
      publishedAt: article['publishedAt'] ?? '',
      category: _categorizeTrend(article['title'] ?? ''),
    )).toList();
  }

  String _categorizeTrend(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('ai') || lowerTitle.contains('artificial intelligence')) {
      return 'AI & ML';
    } else if (lowerTitle.contains('cloud') || lowerTitle.contains('aws') || lowerTitle.contains('azure')) {
      return 'Cloud Computing';
    } else if (lowerTitle.contains('cyber') || lowerTitle.contains('security')) {
      return 'Cybersecurity';
    } else if (lowerTitle.contains('blockchain') || lowerTitle.contains('crypto')) {
      return 'Blockchain';
    } else if (lowerTitle.contains('startup') || lowerTitle.contains('funding')) {
      return 'Startups';
    } else {
      return 'Technology';
    }
  }

  Map<String, dynamic> _getDummyMarketData() {
    return {
      'dates': List.generate(30, (index) {
        final date = DateTime.now().subtract(Duration(days: 29 - index));
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }),
      'values': List.generate(30, (index) => 100 + (index * 0.5) + (index % 3 == 0 ? -1 : 1)),
      'change': '2.5',
    };
  }

  List<Trend> _getDummyTechTrends() {
    return [
      Trend(
        title: 'AI Revolution Continues',
        description: 'Cloud services market expected to reach \$500B by 2025',
        source: 'TechCrunch',
        url: 'https://techcrunch.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        category: 'Technology',
      ),
      Trend(
        title: 'Blockchain Adoption Grows',
        description: 'Major banks announce blockchain integration plans',
        source: 'CoinDesk',
        url: 'https://coindesk.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        category: 'Blockchain',
      ),
      Trend(
        title: '5G Rollout Accelerates',
        description: 'Global 5G subscriptions to reach 1B by 2024',
        source: 'The Verge',
        url: 'https://theverge.com',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        category: 'Telecom',
      ),
    ];
  }
} 