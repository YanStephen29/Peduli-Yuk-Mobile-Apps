import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/masyarakat/article_detail_masyarakat.dart';
import 'package:peduliyuk_api/organization/donation_detail_receiver_screen.dart';

class OrganizationHomePage extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const OrganizationHomePage({Key? key, required this.apiBaseUrl, required this.userId}) : super(key: key);

  @override
  OrganizationHomePageState createState() => OrganizationHomePageState();
}

class OrganizationHomePageState extends State<OrganizationHomePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<dynamic> articles = [];
  List<dynamic> categories = [];
  int? selectedCategoryId;
  List<dynamic> _availableDonations = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    if(!mounted) return;
    setState(() => _isLoading = true);
    await _fetchUserData();
    if (_userData != null && mounted) {
      await Future.wait([
        _fetchArticles(),
        _fetchCategories(),
        _fetchAvailableDonations(),
      ]);
    }
    if(mounted) setState(() => _isLoading = false);
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

  Future<void> _fetchArticles() async {
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

  Future<void> _fetchCategories() async {
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

  Future<void> _fetchAvailableDonations() async {
    if (_userData == null || _userData!['role'] == null) return;
    final String userRole = _userData!['role'];
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_available_donations.php?role=$userRole'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _availableDonations = data['donations']);
        }
      }
    } catch (e) {
      print('Error fetching available donations: $e');
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: fetchInitialData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildProfileHeader(),
          _buildSectionTitle('Donasi Tersedia Untuk Anda'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: _buildAvailableDonationsSection(),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),
          _buildSectionTitle('Artikel Pilihan'),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  ? Icon(Icons.business_outlined, size: 30, color: Colors.grey.shade600)
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
                  _userData?['username'] ?? 'User',
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildAvailableDonationsSection() {
    if (_availableDonations.isEmpty) {
      return _buildEmptyState('Saat ini tidak ada donasi yang tersedia untuk Anda.');
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDonations.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final donation = _availableDonations[index];
          final imageUrl = donation['first_photo_url'] != null && donation['first_photo_url'] != ''
              ? '${widget.apiBaseUrl}/${donation['first_photo_url']}'
              : null;
          return Container(
            width: 280,
            margin: EdgeInsets.only(right: index == _availableDonations.length - 1 ? 0 : 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonationDetailReceiverScreen(
                        apiBaseUrl: widget.apiBaseUrl,
                        donationId: int.parse(donation['donation_id'].toString()),
                        receiverId: widget.userId,
                        onDonationTaken: fetchInitialData,
                      ),
                    ),
                  );
                  if (result == true) {
                    fetchInitialData();
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 50))),
                      )
                    else
                      Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 50))),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 12, right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${donation['donation_type'].toString().toUpperCase()}: ${donation['total_quantity']} item',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dari: ${donation['username'] ?? 'Pengguna Anonim'}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
                          ),
                        ],
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
    if (filteredArticles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _buildEmptyState('Tidak ada artikel pada kategori ini.'),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredArticles.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final article = filteredArticles[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailMasyarakatPage(apiBaseUrl: widget.apiBaseUrl, article: article),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        '${widget.apiBaseUrl}/${article['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article['title'], style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
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
}
