import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:peduliyuk_api/masyarakat/article_detail_masyarakat.dart';
import 'package:peduliyuk_api/masyarakat/suara_kebutuhan_detail_screen.dart';

class MasyarakatHomePage extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const MasyarakatHomePage({Key? key, required this.apiBaseUrl, required this.userId}) : super(key: key);

  @override
  State<MasyarakatHomePage> createState() => _MasyarakatHomePageState();
}

class _MasyarakatHomePageState extends State<MasyarakatHomePage> {
  List<dynamic> articles = [];
  List<dynamic> categories = [];
  int? selectedCategoryId;
  List<dynamic> suaraKebutuhan = [];
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _startAutoScroll();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUserData(),
      fetchArticles(),
      fetchCategories(),
      fetchSuaraKebutuhan(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_user_details.php?user_id=${widget.userId}'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _userData = data['data']);
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (suaraKebutuhan.isNotEmpty) {
        int nextPage = (_currentPage + 1) % suaraKebutuhan.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> fetchArticles() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_articles.php'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => articles = data['articles']);
        }
      }
    } catch (e) {
      print('Error fetching articles: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_categories.php'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => categories = data['categories']);
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchSuaraKebutuhan() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_suara_kebutuhan.php'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => suaraKebutuhan = data['suara_kebutuhan']);
        }
      }
    } catch (e) {
      print('Error fetching suara kebutuhan: $e');
    }
  }

  List<dynamic> get filteredArticles {
    if (selectedCategoryId == null) return articles;
    return articles.where((article) {
      final List<dynamic> articleCategories = json.decode(article['category_ids'] ?? '[]');
      return articleCategories.contains(selectedCategoryId);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildProfileHeader(),

          _buildSectionTitle('Suara Kebutuhan Mendesak'),
          _buildSuaraKebutuhanSlider(),

          const Divider(thickness: 1, height: 32, indent: 16, endIndent: 16),

          _buildSectionTitle('Artikel Untuk Anda'),
          _buildCategoryFilters(),
          const SizedBox(height: 16),
          _buildArticleList(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _userData?['photo'] != null && _userData!['photo'] != ''
                  ? NetworkImage('${widget.apiBaseUrl}/${_userData!['photo']}')
                  : null,
              child: _userData?['photo'] == null || _userData!['photo'] == ''
                  ? Icon(Icons.person_outline, size: 30, color: Colors.grey.shade600)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang,', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9))),
                Text(
                  _userData?['username'] ?? 'Pengguna',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSuaraKebutuhanSlider() {
    if (suaraKebutuhan.isEmpty) return _buildEmptyState('Tidak ada suara kebutuhan saat ini.');

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: suaraKebutuhan.length,
            itemBuilder: (context, index) {
              final item = suaraKebutuhan[index];
              final bool isActive = (index == _currentPage);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: isActive ? 0 : 10),
                child: _buildSuaraKebutuhanCard(item),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(suaraKebutuhan.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: index == _currentPage ? 24 : 8,
              decoration: BoxDecoration(
                color: index == _currentPage ? Theme.of(context).primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSuaraKebutuhanCard(Map<String, dynamic> item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuaraKebutuhanDetailScreen(apiBaseUrl: widget.apiBaseUrl, suaraKebutuhan: item))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network('${widget.apiBaseUrl}/${item['image_url']}', fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: Icon(Icons.campaign, color: Colors.grey[400]))),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center)),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Oleh: ${item['organization_name']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              label: const Text('Semua'),
              selected: selectedCategoryId == null,
              onSelected: (_) => setState(() => selectedCategoryId = null),
            );
          }
          final cat = categories[index - 1];
          final int id = int.parse(cat['id'].toString());
          return FilterChip(
            label: Text(cat['name']),
            selected: selectedCategoryId == id,
            onSelected: (_) => setState(() => selectedCategoryId = id),
          );
        },
      ),
    );
  }

  Widget _buildArticleList() {
    if (filteredArticles.isEmpty) return _buildEmptyState('Tidak ada artikel pada kategori ini.');
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filteredArticles.length,
        itemBuilder: (context, index) {
          final article = filteredArticles[index];
          return Container(
            width: 240,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleDetailMasyarakatPage(apiBaseUrl: widget.apiBaseUrl, article: article))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network('${widget.apiBaseUrl}/${article['image_url']}', fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400]))),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(article['title'], style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(article['created_at'], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}