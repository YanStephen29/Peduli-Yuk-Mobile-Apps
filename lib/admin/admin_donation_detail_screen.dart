import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDonationDetailScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int donationId;
  final VoidCallback onUpdate;

  const AdminDonationDetailScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.donationId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<AdminDonationDetailScreen> createState() => _AdminDonationDetailScreenState();
}

class _AdminDonationDetailScreenState extends State<AdminDonationDetailScreen> {
  Map<String, dynamic>? donationDetails;
  List<dynamic> donationItems = [];
  Map<String, dynamic>? userDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDonationAndUserDetails();
  }

  Future<void> _fetchDonationAndUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final donationResponse = await http.get(Uri.parse('${widget.apiBaseUrl}/get_donation_details.php?donation_id=${widget.donationId}'));

      if (donationResponse.statusCode == 200) {
        final donationData = json.decode(donationResponse.body);
        if (donationData['status'] == 'success') {
          setState(() {
            donationDetails = donationData['donation'];
            donationItems = donationData['items'];
          });

          if (donationDetails != null && donationDetails!['id_user'] != null) {
            final userResponse = await http.post(
              Uri.parse('${widget.apiBaseUrl}/get_user_by_id.php'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'user_id': donationDetails!['id_user']}),
            );

            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);
              if (userData['status'] == 'success') {
                setState(() {
                  userDetails = userData['user'];
                });
              } else {
                _errorMessage = userData['message'] ?? 'Gagal memuat detail pengguna.';
              }
            } else {
              _errorMessage = 'Gagal terhubung ke server untuk detail pengguna: ${userResponse.statusCode}';
            }
          }
        } else {
          _errorMessage = donationData['message'] ?? 'Gagal mengambil detail donasi.';
        }
      } else {
        _errorMessage = 'Gagal terhubung ke server untuk detail donasi: ${donationResponse.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
      print('Error fetching donation and user details: $e');
    } finally {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptDonation(String acceptTo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Memproses..."),
          ],
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/update_donation_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'donation_id': widget.donationId,
          'accept_to': acceptTo,
        }),
      );
      if(!mounted) return;
      Navigator.of(context).pop();

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'])));
        widget.onUpdate();
        Navigator.of(context).pop();
      } else {
        _showMessage('Error', data['message'] ?? 'Gagal menerima donasi.');
      }
    } catch (e) {
      if(!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Error', 'Kesalahan jaringan: $e');
      print('Error accepting donation: $e');
    }
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
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

  String _getAcceptToDisplayName(String acceptTo) {
    switch (acceptTo) {
      case 'lembaga_sosial': return 'Lembaga Sosial';
      case 'umkm': return 'UMKM';
      case '-': return 'Belum ditentukan';
      default: return acceptTo;
    }
  }

  void _showAcceptToDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Terima Donasi Untuk"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Lembaga Sosial"),
                onTap: () {
                  Navigator.of(context).pop();
                  _acceptDonation('lembaga_sosial');
                },
              ),
              ListTile(
                title: const Text("UMKM"),
                onTap: () {
                  Navigator.of(context).pop();
                  _acceptDonation('umkm');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Permintaan Donasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center)))
          : donationDetails == null
          ? const Center(child: Text('Donasi tidak ditemukan.'))
          : buildContent(),

      bottomNavigationBar: donationDetails!['status'] == 'Waiting For Approval'
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showAcceptToDialog,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Terima Donasi Untuk'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserCard(),
          const SizedBox(height: 20),
          _buildDonationInfoCard(),
          const SizedBox(height: 20),
          Text('Item dalam Donasi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (donationItems.isEmpty)
            const Text('Tidak ada item yang terkait.', style: TextStyle(fontStyle: FontStyle.italic)),
          ...donationItems.map((item) => _buildItemExpansionTile(item)).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: userDetails?['photo'] != null && userDetails!['photo'] != ''
                  ? NetworkImage('${widget.apiBaseUrl}/${userDetails!['photo']}') as ImageProvider
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userDetails?['username'] ?? 'Nama Pengguna', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Telp: ${userDetails?['no_telp'] ?? '-'}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
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
                Text('Donasi #${donationDetails!['id']}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(donationDetails!['status'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: _getStatusColor(donationDetails!['status']),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(Icons.category_outlined, 'Jenis Donasi', donationDetails!['type'].toString().toUpperCase()),
            _buildDetailRow(Icons.calendar_today_outlined, 'Tanggal Dibuat', donationDetails!['created_at']),
            _buildDetailRow(Icons.business_center_outlined, 'Diterima Oleh', _getAcceptToDisplayName(donationDetails!['accept_to'] ?? '-')),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
    String? imageUrlFront, imageUrlBack;
    final isPakaian = donationDetails!['type'] == 'pakaian';
    final itemNameOrType = isPakaian ? _getClothingDisplayName(item['clothing_type'] ?? '') : (item['item_name'] ?? 'Tidak ada nama');

    if (item['front_photo_url'] != null && item['front_photo_url'] != '') imageUrlFront = '${widget.apiBaseUrl}/${item['front_photo_url']}';
    if (item['back_photo_url'] != null && item['back_photo_url'] != '') imageUrlBack = '${widget.apiBaseUrl}/${item['back_photo_url']}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(itemNameOrType, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.format_size, 'Ukuran', item['size'] ?? '-'),
          _buildDetailRow(Icons.report_problem_outlined, 'Kekurangan', item['defects'] ?? 'Tidak ada'),
          const SizedBox(height: 16),
          if (imageUrlFront != null || imageUrlBack != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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