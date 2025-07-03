  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';

  class DonationDetailScreen extends StatefulWidget {
    final String apiBaseUrl;
    final int donationId;
    const DonationDetailScreen({Key? key, required this.apiBaseUrl, required this.donationId}) : super(key: key);
    @override
    State<DonationDetailScreen> createState() => _DonationDetailScreenState();
  }

  class _DonationDetailScreenState extends State<DonationDetailScreen> {
    Map<String, dynamic>? donationDetails;
    List<dynamic> donationItems = [];
    bool _isLoading = true;
    String? _errorMessage;

    @override
    void initState() {
      super.initState();
      _fetchDonationDetails();
    }

    Future<void> _fetchDonationDetails() async {
      if(!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_donation_details.php?donation_id=${widget.donationId}'));
        if (response.statusCode == 200 && mounted) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              donationDetails = data['donation'];
              donationItems = data['items'];
            });
          } else {
            setState(() => _errorMessage = data['message'] ?? 'Gagal mengambil detail donasi.');
          }
        } else if (mounted) {
          setState(() => _errorMessage = 'Gagal terhubung ke server: ${response.statusCode}');
        }
      } catch (e) {
        if(mounted) setState(() => _errorMessage = 'Terjadi kesalahan jaringan: $e');
        print('Error fetching donation details: $e');
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }

    Color _getStatusColor(String status) {
      switch (status) {
        case 'Waiting For Approval': return Colors.orange;
        case 'Waiting For Receiver': return Colors.blue;
        case 'Found Receiver': return Colors.indigo;
        case 'On Delivery': return Colors.purple;
        case 'Received': return Colors.green;
        case 'Waiting For Feedback': return Colors.teal;
        case 'Success': return Colors.lightGreen;
        default: return Colors.grey;
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Donasi Anda'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)))
            : donationDetails == null
            ? const Center(child: Text('Donasi tidak ditemukan.'))
            : _buildContent(),
      );
    }

    Widget _buildContent() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDonationInfoCard(),
            const SizedBox(height: 24),
            Text(
              'Item dalam Donasi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (donationItems.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('Tidak ada rincian item.')))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: donationItems.length,
                itemBuilder: (context, index) => _buildItemExpansionTile(donationItems[index]),
              ),
          ],
        ),
      );
    }

    Widget _buildDonationInfoCard() {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Donasi #${donationDetails!['id']}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(
                      donationDetails!['status'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: _getStatusColor(donationDetails!['status']),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.category_outlined, 'Jenis Donasi', donationDetails!['type'].toString().toUpperCase()),
              _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Dibuat', donationDetails!['created_at']),
              _buildInfoRow(Icons.business_center_outlined, 'Diterima Oleh', donationDetails!['accept_to'] == '-' ? 'Belum ditentukan' : donationDetails!['accept_to'].toString().replaceAll('_', ' ').split(' ').map((l) => l[0].toUpperCase() + l.substring(1)).join(' ')),
            ],
          ),
        ),
      );
    }

    Widget _buildInfoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Text('$label:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    Widget _buildItemExpansionTile(Map<String, dynamic> item) {
      final isPakaian = donationDetails!['type'] == 'pakaian';
      final itemNameOrType = isPakaian
          ? (item['clothing_type'].toString().replaceFirst('pakaian_dalam', 'Pakaian Dalam').split('_').map((l) => l[0].toUpperCase() + l.substring(1)).join(' '))
          : (item['item_name'] ?? 'Item');

      final itemSize = item['size'] ?? '-';
      final itemDefects = item['defects'] ?? 'Tidak ada';

      String? imageUrlFront;
      String? imageUrlBack;
      if (item['front_photo_url'] != null && item['front_photo_url'].isNotEmpty) imageUrlFront = '${widget.apiBaseUrl}/${item['front_photo_url']}';
      if (item['back_photo_url'] != null && item['back_photo_url'].isNotEmpty) imageUrlBack = '${widget.apiBaseUrl}/${item['back_photo_url']}';

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrlFront != null
                  ? Image.network(imageUrlFront, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                  : Icon(isPakaian ? Icons.checkroom : Icons.widgets_outlined, color: Colors.grey.shade400),
            ),
          ),
          title: Text(itemNameOrType, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Ukuran: $itemSize', style: TextStyle(color: Colors.grey.shade700)),
          childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 16),
            Text('Kekurangan: $itemDefects', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (imageUrlFront != null || imageUrlBack != null)
              Row(
                children: [
                  if (imageUrlFront != null) Expanded(child: _buildImageDisplay('Foto Depan', imageUrlFront)),
                  if (imageUrlFront != null && imageUrlBack != null) const SizedBox(width: 10),
                  if (imageUrlBack != null) Expanded(child: _buildImageDisplay('Foto Belakang', imageUrlBack)),
                ],
              )
            else
              const Center(child: Text('Tidak ada foto untuk item ini.', style: TextStyle(fontStyle: FontStyle.italic))),
          ],
        ),
      );
    }

    Widget _buildImageDisplay(String title, String imageUrl) {
      return Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
        ],
      );
    }
  }