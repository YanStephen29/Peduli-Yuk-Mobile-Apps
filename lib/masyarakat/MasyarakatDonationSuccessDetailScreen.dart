// lib/screens/masyarakat/MasyarakatDonationSuccessDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MasyarakatDonationSuccessDetailScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int donationId;

  const MasyarakatDonationSuccessDetailScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.donationId,
  }) : super(key: key);

  @override
  State<MasyarakatDonationSuccessDetailScreen> createState() => _MasyarakatDonationSuccessDetailScreenState();
}

class _MasyarakatDonationSuccessDetailScreenState extends State<MasyarakatDonationSuccessDetailScreen> {
  // --- STATE DAN LOGIKA ANDA TETAP SAMA ---
  Map<String, dynamic>? donationDetail;
  bool _isLoading = true;
  String _errorMessage = '';

  // --- SEMUA FUNGSI LOGIKA ANDA (initState, fetch, dll) TIDAK DIUBAH ---
  @override
  void initState() {
    super.initState();
    _fetchDonationDetail();
  }

  Future<void> _fetchDonationDetail() async {
    if(!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_successful_donation_details.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'donation_id': widget.donationId}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            donationDetail = data['donation_detail'];
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal mengambil detail donasi.';
          });
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server: ${response.statusCode}';
        });
      }
    } catch (e) {
      if(mounted) setState(() {
        _errorMessage = 'Terjadi kesalahan jaringan: $e';
      });
      print('Error fetching successful donation detail: $e');
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  // --- BAGIAN UI (TAMPILAN) YANG DIPERBAGUS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Riwayat Donasi'),
        // AppBar akan otomatis mengikuti tema
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage, textAlign: TextAlign.center)))
          : donationDetail == null
          ? const Center(child: Text('Data donasi tidak tersedia.'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildItemDetailCard(),
        const SizedBox(height: 16),
        _buildReceiverInfoCard(),
        if (donationDetail!['feedback_comment'] != null && donationDetail!['feedback_comment'].isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildFeedbackCard(),
        ],
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Donasi #${donationDetail!['donation_id']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    donationDetail!['donation_status'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green.shade600,
                  avatar: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.category_outlined, 'Jenis Donasi', donationDetail!['donation_type'].toString().toUpperCase()),
            _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Donasi', donationDetail!['donation_created_at']),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailCard() {
    String itemName;
    String? imageUrl;
    if (donationDetail!['donation_type'] == 'pakaian') {
      itemName = _getClothingDisplayName(donationDetail!['clothing_type'] ?? 'N/A');
      imageUrl = donationDetail!['clothing_front_photo_url'];
    } else {
      itemName = donationDetail!['item_name'] ?? 'N/A';
      imageUrl = donationDetail!['item_front_photo_url'];
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Rincian Item", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              '${widget.apiBaseUrl}/$imageUrl',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            )
          else
            Container(height: 180, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildInfoRow(Icons.label_outline, 'Nama/Jenis', itemName),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverInfoCard() {
    final String? receivedPhotoUrl = donationDetail!['received_photo_url'];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Informasi Penerimaan", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Penerima', donationDetail!['receiver_username'] ?? 'Tidak diketahui'),
            _buildInfoRow(Icons.local_shipping_outlined, 'Metode Pengiriman', donationDetail!['delivery_method'] ?? 'N/A'),
            _buildInfoRow(Icons.event_available_outlined, 'Tanggal Diterima', donationDetail!['received_at'] ?? 'N/A'),
            if (receivedPhotoUrl != null && receivedPhotoUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Bukti Penerimaan:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${widget.apiBaseUrl}/$receivedPhotoUrl',
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Text('Gagal memuat gambar bukti.'),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final dynamic rawRating = donationDetail!['feedback_rating'];
    double rating = 0.0;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating) ?? 0.0;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review_outlined, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text("Ulasan Penerima", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
              ],
            ),
            const SizedBox(height: 12),
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, index) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              itemCount: 5,
              itemSize: 22.0, // Ukuran bintang bisa disesuaikan
              unratedColor: Colors.amber.withAlpha(50),
            ),

            const SizedBox(height: 12),
            Text(
              '"${donationDetail!['feedback_comment']}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}