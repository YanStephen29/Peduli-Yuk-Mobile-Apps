import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_article.dart';
import 'package:peduliyuk_api/controller/admin_main_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleDetailPage extends StatefulWidget {
  final String apiBaseUrl;
  final Map<String, dynamic> article;
  final int adminId;
  const ArticleDetailPage({Key? key, required this.apiBaseUrl, required this.article, required this.adminId}) : super(key: key);

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_article_categories.php?id=${widget.article['id']}'));
    if(!mounted) return;
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      setState(() {
        categories = List<String>.from(data['categories']);
      });
    }
  }

  Future<void> deleteArticle(BuildContext context) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus artikel ini secara permanen?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/delete_article.php'),
        body: {'id': widget.article['id'].toString()},
      );
      if(!mounted) return;
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Artikel berhasil dihapus')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => AdminMainScreen(
              apiBaseUrl: widget.apiBaseUrl,
              adminId: widget.adminId,
            ),
          ),
              (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus artikel')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.article['title'] ?? 'Detail Artikel',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              background: widget.article['image_url'] != null && widget.article['image_url'] != ''
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${widget.apiBaseUrl}/${widget.article['image_url']}',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white))),
                  ),

                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent, Colors.black54],
                          stops: [0.0, 0.5, 1.0]
                      ),
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),

            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditArticlePage(apiBaseUrl: widget.apiBaseUrl, article: widget.article, adminId: widget.adminId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => deleteArticle(context),
              ),
            ],
          ),

          SliverPadding(
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
                const SizedBox(height: 24),

                if (categories.isNotEmpty) ...[
                  Text('Kategori', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: categories.map((cat) => Chip(
                      label: Text(cat),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  widget.article['description'] ?? 'Tidak ada deskripsi.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),

                if (widget.article['source_link'] != null && widget.article['source_link'].isNotEmpty)
                  InkWell(
                    onTap: () {
                      final uri = Uri.parse(widget.article['source_link']);
                      if (uri.isAbsolute) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
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
              ]),
            ),
          ),
        ],
      ),
    );
  }
}