import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'MasyarakatDonationSuccessDetailScreen.dart';

class MasyarakatDonationHistoryScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;

  const MasyarakatDonationHistoryScreen({Key? key, required this.apiBaseUrl, required this.userId}) : super(key: key);

  @override
  State<MasyarakatDonationHistoryScreen> createState() => _MasyarakatDonationHistoryScreenState();
}

class _MasyarakatDonationHistoryScreenState extends State<MasyarakatDonationHistoryScreen> {
  List<dynamic> successfulDonations = [];
  bool _isLoadingDonations = true;

  @override
  void initState() {
    super.initState();
    _fetchSuccessfulDonations();
  }

  Future<void> _fetchSuccessfulDonations() async {
    if(!mounted) return;
    setState(() {
      _isLoadingDonations = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_my_successful_donations.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            successfulDonations = data['donations'];
          });
        } else {
          _showMessage('Error', data['message'] ?? 'Gagal mengambil riwayat donasi.');
        }
      } else if (mounted) {
        _showMessage('Error', 'Gagal terhubung ke server: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) _showMessage('Error', 'Terjadi kesalahan jaringan: $e');
      print('Error fetching successful donations: $e');
    } finally {
      if(mounted) {
        setState(() {
          _isLoadingDonations = false;
        });
      }
    }
  }

  void _showMessage(String title, String message) {
    if(!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  String _getClothingDisplayName(String type) {
    switch (type) {
      case 'kaos': return 'Kaos';
      case 'kemeja': return 'Kemeja';
      case 'celana': return 'Celana';
      case 'pakaian_dalam': return 'Pakaian Dalam';
      case 'lainnya': return 'Lainnya';
      default: return type;
    }
  }


  @override
  Widget build(BuildContext context) {
    // Menghapus Scaffold yang tidak perlu
    if (_isLoadingDonations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (successfulDonations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchSuccessfulDonations,
      child: _buildDonationHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _fetchSuccessfulDonations,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                      Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Riwayat Donasi Kosong',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua donasi Anda yang telah berhasil disalurkan akan muncul di sini.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: successfulDonations.length,
      itemBuilder: (context, index) {
        final donation = successfulDonations[index];
        return _buildHistoryCard(donation);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> donation) {
    String? imageUrl;
    String itemName = 'Donasi ID: #${donation['id']}'; // Default

    if (donation['type'] == 'pakaian') {
      itemName = _getClothingDisplayName(donation['clothing_type'] ?? 'Pakaian');
      if (donation['clothing_front_photo_url'] != null && donation['clothing_front_photo_url'] != '') {
        imageUrl = '${widget.apiBaseUrl}/${donation['clothing_front_photo_url']}';
      }
    } else if (donation['type'] == 'barang') {
      itemName = donation['item_name'] ?? 'Donasi Barang';
      if (donation['item_front_photo_url'] != null && donation['item_front_photo_url'] != '') {
        imageUrl = '${widget.apiBaseUrl}/${donation['item_front_photo_url']}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Flow navigasi tetap sama
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MasyarakatDonationSuccessDetailScreen(
                apiBaseUrl: widget.apiBaseUrl,
                donationId: int.parse(donation['id'].toString()),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                  )
                      : Container(color: Colors.grey.shade200, child: Icon(Icons.redeem, color: Colors.grey.shade400)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: #${donation['id']} • ${donation['created_at']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: const Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      backgroundColor: Colors.green.shade600, // Warna hijau untuk status sukses
                      avatar: const Icon(Icons.check_circle, color: Colors.white, size: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: 0.0, vertical: -4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}