import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_suara_kebutuhan_screen.dart';
import 'suara_kebutuhan_detail_screen.dart';
import 'package:intl/intl.dart';

class SuaraKebutuhanListScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const SuaraKebutuhanListScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
  }) : super(key: key);

  @override
  SuaraKebutuhanListScreenState createState() => SuaraKebutuhanListScreenState();
}

class SuaraKebutuhanListScreenState extends State<SuaraKebutuhanListScreen> {
  List<dynamic> _suaraKebutuhanList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchSuaraKebutuhan();
  }

  Future<void> fetchSuaraKebutuhan() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_suara_kebutuhan.php?user_id=${widget.userId}'));
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _suaraKebutuhanList = data['suara_kebutuhan'];
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Failed to fetch data.');
        }
      } else if(mounted) {
        setState(() => _errorMessage = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) setState(() => _errorMessage = 'Network error: $e');
      print('Error fetching suara kebutuhan: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: fetchSuaraKebutuhan,
        child: _suaraKebutuhanList.isEmpty
            ? _buildEmptyState()
            : _buildSuaraKebutuhanList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSuaraKebutuhanScreen(
                apiBaseUrl: widget.apiBaseUrl,
                userId: widget.userId,
              ),
            ),
          );
          if (result == true) {
            fetchSuaraKebutuhan();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchSuaraKebutuhan,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Suara Kebutuhan',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan tombol + untuk membuat "Suara Kebutuhan" pertama Anda dan jangkau para donatur.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSuaraKebutuhanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _suaraKebutuhanList.length,
      itemBuilder: (context, index) {
        return _buildSuaraKebutuhanCard(_suaraKebutuhanList[index]);
      },
    );
  }

  Widget _buildSuaraKebutuhanCard(Map<String, dynamic> item) {
    final imageUrl = item['image_url'] != null && item['image_url'] != ''
        ? '${widget.apiBaseUrl}/${item['image_url']}'
        : null;
    final String deadlineText = item['deadline'] != null && item['deadline'].isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['deadline']))
        : 'Tidak terbatas';
    final deadlineDate = DateTime.tryParse(item['deadline'] ?? '');
    final bool isExpired = deadlineDate != null && deadlineDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigasi ke detail, flow tetap sama
          final bool? result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SuaraKebutuhanDetailScreen(
                apiBaseUrl: widget.apiBaseUrl,
                suaraKebutuhan: item,
                onUpdateOrDelete: fetchSuaraKebutuhan,
              ),
            ),
          );
          if (result == true) {
            fetchSuaraKebutuhan();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            SizedBox(
              height: 160,
              width: double.infinity,
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
              )
                  : Container(color: Colors.grey[200], child: Icon(Icons.campaign, color: Colors.grey.shade400, size: 60)),
            ),
            // Konten Teks
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: isExpired ? Colors.red.shade700 : Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Batas Waktu: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                      Text(
                        deadlineText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red.shade700 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                      ),
                      Text(
                        item['status'] ?? 'Aktif',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: (item['status'] == 'Tercapai')
                              ? Colors.green.shade700
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Lihat Detail', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18, color: Theme.of(context).primaryColor)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
