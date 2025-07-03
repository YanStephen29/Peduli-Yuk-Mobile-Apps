import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/admin/add_article.dart';
import 'package:peduliyuk_api/admin/ArticleDetailPage.dart';

class ArtikelAdminPage extends StatefulWidget {
  final String apiBaseUrl;
  final int adminId;
  const ArtikelAdminPage({Key? key, required this.apiBaseUrl, required this.adminId}) : super(key: key);

  @override
  State<ArtikelAdminPage> createState() => _ArtikelAdminPageState();
}

class _ArtikelAdminPageState extends State<ArtikelAdminPage> {
  List<dynamic> articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_articles.php'));
      if (mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            articles = data['articles'];
          });
        }
      }
    } catch (e) {
      print('Error fetching articles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat artikel: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias, // Penting untuk gambar
      child: InkWell(
        onTap: () {
          // Navigasi ke detail, flow tetap sama
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailPage(
                apiBaseUrl: widget.apiBaseUrl,
                article: article,
                adminId: widget.adminId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Artikel
            SizedBox(
              height: 150,
              width: double.infinity,
              child: article['image_url'] != null && article['image_url'] != ''
                  ? Image.network(
                '${widget.apiBaseUrl}/${article['image_url']}',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
              )
                  : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 40))),
            ),
            // Judul dan Tanggal
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'Tanpa Judul',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        article['created_at'] ?? 'Tanpa Tanggal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchArticles,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Belum ada artikel.\nTekan tombol + untuk menambah artikel baru.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildArticleCard(articles[index]);
        },
      ),
    );
  }
}