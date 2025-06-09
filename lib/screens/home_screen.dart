import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/company_model.dart';
import '../data/posts.dart';
import '../data/companies.dart';
import '../widgets/post_carousel.dart';
import '../widgets/company_card.dart';
import '../screens/all_companies_screen.dart';
import '../screens/all_posts_screen.dart';
import '../screens/all_trends_screen.dart';
import 'dart:ui';
import '../services/trends_service.dart';
import '../models/trend_model.dart';

class HomeScreen extends StatefulWidget {
  final Function() toggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrendsService _trendsService = TrendsService();
  List<TrendModel> _aiTrends = [];
  bool _isLoading = true;
  String? _error;

  // Add state for search and posts
  List<PostModel> _filteredPosts = List.from(dummyPosts);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAITrends();
  }

  Future<void> _loadAITrends() async {
    try {
      final trends = await _trendsService.getTechTrends();
      setState(() {
        _aiTrends = trends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _filteredPosts = dummyPosts.where((post) =>
        post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    });
  }

  void _addDummyPost() {
    setState(() {
      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Insight',
        content: 'This is a new custom insight.',
        author: 'You',
        date: DateTime.now().toIso8601String().split('T')[0],
        category: 'Custom',
        likes: 0,
        comments: [],
        imageUrl: '',
        tags: ['Custom'],
      );
      dummyPosts.insert(0, newPost);
      _filteredPosts.insert(0, newPost);
    });
  }

  void _deletePost(String id) {
    setState(() {
      dummyPosts.removeWhere((post) => post.id == id);
      _filteredPosts.removeWhere((post) => post.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWeb = kIsWeb;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            stretch: true,
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: colorScheme.surface.withOpacity(0.8),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  'Startup Hub',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.primary,
                ),
                onPressed: widget.toggleTheme,
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Latest Posts Section
                _buildSectionHeader(
                  context,
                  'Latest Insights',
                  'View all',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllPostsScreen(
                          posts: dummyPosts,
                        ),
                      ),
                    );
                  },
                ),
                // Minimal search bar and + button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search insights...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Insight',
                      onPressed: _addDummyPost,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PostCarousel(
                    posts: _filteredPosts,
                    onDelete: _deletePost,
                  ),
                ),
                const SizedBox(height: 32),

                // Featured Companies Section
                _buildFeaturedCompanies(),

                // Funding Highlights Section
                _buildSectionHeader(
                  context,
                  'Funding Highlights',
                  'View all',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllCompaniesScreen(
                          companies: dummyCompanies,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildFundingHighlights(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFundingHighlights(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildFundingHighlight(
            context,
            'TechVision AI',
            'Series A',
            '\$25M',
            'Andreessen Horowitz',
          ),
          const Divider(),
          _buildFundingHighlight(
            context,
            'GreenEnergy Solutions',
            'Series B',
            '\$40M',
            'Tiger Global',
          ),
          const Divider(),
          _buildFundingHighlight(
            context,
            'HealthTech Innovations',
            'Series C',
            '\$50M',
            'General Catalyst',
          ),
        ],
      ),
    );
  }

  Widget _buildFundingHighlight(
    BuildContext context,
    String company,
    String round,
    String amount,
    String investor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text(
              company[0],
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$round • $amount',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            investor,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCompanies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Companies',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllCompaniesScreen(
                        companies: dummyCompanies,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxWidth > 600 ? 450 : 600,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: dummyCompanies.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: constraints.maxWidth > 600 ? 320 : constraints.maxWidth - 32,
                    margin: const EdgeInsets.only(right: 16),
                    child: CompanyCard(
                      company: dummyCompanies[index],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
} 