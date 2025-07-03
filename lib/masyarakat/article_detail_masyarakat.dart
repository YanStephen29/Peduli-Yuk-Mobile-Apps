import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailMasyarakatPage extends StatefulWidget {
  final Map<String, dynamic> article;
  final String apiBaseUrl;

  const ArticleDetailMasyarakatPage({
    Key? key,
    required this.article,
    required this.apiBaseUrl,
  }) : super(key: key);

  @override
  _ArticleDetailMasyarakatPageState createState() =>
      _ArticleDetailMasyarakatPageState();
}

class _ArticleDetailMasyarakatPageState
    extends State<ArticleDetailMasyarakatPage> {
  List<String> categories = [];
  List<dynamic> relatedArticles = [];
  bool _isLoadingRelatedArticles = true;

  @override
  void initState() {
    super.initState();
    fetchCategories().then((_) {
      if (categories.isNotEmpty) {
        fetchRelatedArticles();
      } else {
        setState(() {
          _isLoadingRelatedArticles = false;
        });
      }
    });
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(
          '${widget.apiBaseUrl}/get_article_categories.php?id=${widget.article['id']}'));
      if(!mounted) return;
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          categories = List<String>.from(data['categories'].map((item) => item.toString()));
        });
      }
    } catch (e) {
      print('Exception fetching categories: $e');
    }
  }

  Future<void> fetchRelatedArticles() async {
    setState(() => _isLoadingRelatedArticles = true);
    if (categories.isEmpty) {
      setState(() => _isLoadingRelatedArticles = false);
      return;
    }
    String categoryQuery = categories.join(',');
    try {
      final response = await http.get(Uri.parse(
          '${widget.apiBaseUrl}/get_articles_by_category.php?categoryIds=$categoryQuery&articleId=${widget.article['id']}'));
      if(!mounted) return;
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() => relatedArticles = data['articles']);
      } else {
        setState(() => relatedArticles = []);
      }
    } catch (e) {
      print('Exception fetching related articles: $e');
      setState(() => relatedArticles = []);
    } finally {
      if(mounted) {
        setState(() => _isLoadingRelatedArticles = false);
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildContentSliver(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final String imageUrl = widget.article['image_url'] != null && widget.article['image_url'] != ''
        ? '${widget.apiBaseUrl}/${widget.article['image_url']}'
        : '';
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.article['title'] ?? 'Detail Artikel',
          style: const TextStyle(fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        background: imageUrl.isNotEmpty
            ? Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white))),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black54],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        )
            : Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 80, color: Colors.white)),
      ),
    );
  }

  Widget _buildContentSliver() {
    return SliverPadding(
      padding: const EdgeInsets.all(20.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            widget.article['title'] ?? 'Tanpa Judul',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                widget.article['created_at'] ?? 'Tanggal tidak diketahui',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: categories.map((cat) => Chip(
                label: Text(cat, style: TextStyle(color: Theme.of(context).primaryColor)),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                side: BorderSide.none,
              )).toList(),
            ),
          ],
          const Divider(height: 32),
          Text(
            widget.article['description'] ?? 'Tidak ada deskripsi.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.grey.shade800),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 24),
          if (widget.article['source_link'] != null && widget.article['source_link'].isNotEmpty)
            InkWell(
              onTap: () => _launchURL(widget.article['source_link']),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Kunjungi Sumber Artikel',
                      style: TextStyle(color: Colors.blue.shade700, decoration: TextDecoration.underline, decorationColor: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 40),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Artikel Terkait',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildRelatedArticlesSection(),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildRelatedArticlesSection() {
    if (_isLoadingRelatedArticles) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    }
    if (relatedArticles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('Tidak ada artikel terkait.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: relatedArticles.length,
        itemBuilder: (context, index) {
          final relatedArticle = relatedArticles[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailMasyarakatPage(
                        apiBaseUrl: widget.apiBaseUrl,
                        article: relatedArticle,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        '${widget.apiBaseUrl}/${relatedArticle['image_url']}',
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
                            Text(
                              relatedArticle['title'],
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              relatedArticle['created_at'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            ),
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