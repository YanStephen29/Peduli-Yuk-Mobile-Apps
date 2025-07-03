import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'edit_suara_kebutuhan_screen.dart';

class SuaraKebutuhanDetailScreen extends StatelessWidget {
  final String apiBaseUrl;
  final Map<String, dynamic> suaraKebutuhan;
  final VoidCallback onUpdateOrDelete;

  const SuaraKebutuhanDetailScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.suaraKebutuhan,
    required this.onUpdateOrDelete,
  }) : super(key: key);

  Future<void> _deleteSuaraKebutuhan(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus suara kebutuhan ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/delete_suara_kebutuhan.php'),
          body: {'id': suaraKebutuhan['id'].toString()},
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 && data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suara Kebutuhan berhasil dihapus!')),
          );
          onUpdateOrDelete();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: ${data['message'] ?? 'Unknown error'}.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error jaringan: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final imageUrl = suaraKebutuhan['image_url'] != null && suaraKebutuhan['image_url'].isNotEmpty
        ? '$apiBaseUrl/${suaraKebutuhan['image_url']}'
        : null;

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
                suaraKebutuhan['title'] ?? 'Detail',
                style: const TextStyle(fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              background: imageUrl != null
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
                  : Container(color: Colors.grey.shade300, child: const Icon(Icons.campaign, size: 80, color: Colors.white)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditSuaraKebutuhanScreen(
                        apiBaseUrl: apiBaseUrl,
                        suaraKebutuhan: suaraKebutuhan,
                      ),
                    ),
                  );
                  if (result == true) {
                    onUpdateOrDelete();
                    Navigator.pop(context, true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteSuaraKebutuhan(context),
              ),
            ],
          ),
          _buildContentSliver(context),
        ],
      ),
    );
  }

  Widget _buildContentSliver(BuildContext context) {
    final String deadlineText = suaraKebutuhan['deadline'] != null && suaraKebutuhan['deadline'].isNotEmpty
        ? DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(suaraKebutuhan['deadline']))
        : 'Tidak ada batas waktu';
    final String createdDateText = suaraKebutuhan['created_at'] != null
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(suaraKebutuhan['created_at']))
        : 'N/A';

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                suaraKebutuhan['title'] ?? 'Judul Tidak Tersedia',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Dibuat oleh ${suaraKebutuhan['username'] ?? 'Pengguna'} pada $createdDateText',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            const Divider(height: 32),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(context, Icons.timer_outlined, 'Batas Waktu', deadlineText, isHighlighted: true),
                    const Divider(),
                    _buildInfoRow(context, Icons.info_outline, 'Status', suaraKebutuhan['status'] ?? 'Aktif'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),


            Text(
              'Deskripsi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              suaraKebutuhan['description'] ?? 'Deskripsi tidak tersedia.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.grey.shade800),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isHighlighted ? Theme.of(context).primaryColor : Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    color: isHighlighted ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}