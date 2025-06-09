import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trend_model.dart';

class TrendsService {
  // Using Alpha Vantage API for market data (free tier)
  static const String _alphaVantageApiKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String _alphaVantageBaseUrl = 'https://www.alphavantage.co/query';

  // Using NewsAPI for tech trends (we already have the API key)
  static const String _newsApiKey = '075838cfc27f4306b755bd8a3e07ffc1';
  static const String _newsApiBaseUrl = 'https://newsapi.org/v2';

  Future<Map<String, dynamic>> getMarketTrends() async {
    try {
      // Get tech sector performance
      final response = await http.get(
        Uri.parse('$_alphaVantageBaseUrl?function=TIME_SERIES_DAILY&symbol=XLK&apikey=$_alphaVantageApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processMarketData(data);
      } else {
        // Fallback to dummy data if API fails
        return _getDummyMarketData();
      }
    } catch (e) {
      // Fallback to dummy data if API fails
      return _getDummyMarketData();
    }
  }

  Future<List<Trend>> getTechTrends() async {
    try {
      final response = await http.get(
        Uri.parse('$_newsApiBaseUrl/top-headlines?category=technology&language=en&apiKey=$_newsApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processTechTrends(data);
      } else {
        // Fallback to dummy data if API fails
        return _getDummyTechTrends();
      }
    } catch (e) {
      // Fallback to dummy data if API fails
      return _getDummyTechTrends();
    }
  }

  Map<String, dynamic> _processMarketData(Map<String, dynamic> data) {
    // Process the market data from Alpha Vantage
    // This is a simplified version - you can expand it based on your needs
    final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>;
    final dates = timeSeries.keys.toList()..sort();
    final values = dates.map((date) {
      final dayData = timeSeries[date] as Map<String, dynamic>;
      return double.parse(dayData['4. close']);
    }).toList();

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