import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DonationDetailReceiverScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int donationId;
  final int receiverId;
  final VoidCallback onDonationTaken;

  const DonationDetailReceiverScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.donationId,
    required this.receiverId,
    required this.onDonationTaken,
  }) : super(key: key);

  @override
  State<DonationDetailReceiverScreen> createState() => _DonationDetailReceiverScreenState();
}

class _DonationDetailReceiverScreenState extends State<DonationDetailReceiverScreen> {
  Map<String, dynamic>? donationDetails;
  List<dynamic> donationItems = [];
  Map<String, dynamic>? donatorDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final donationResponse = await http.get(Uri.parse('${widget.apiBaseUrl}/get_donation_details.php?donation_id=${widget.donationId}'));

      if (donationResponse.statusCode == 200) {
        final donationData = json.decode(donationResponse.body);
        if (donationData['status'] == 'success') {
          donationDetails = donationData['donation'];
          donationItems = donationData['items'];

          if (donationDetails != null && donationDetails!['id_user'] != null) {
            final userResponse = await http.post(
              Uri.parse('${widget.apiBaseUrl}/get_user_by_id.php'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'user_id': donationDetails!['id_user']}),
            );
            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);
              if (userData['status'] == 'success') {
                donatorDetails = userData['user'];
              }
            }
          }
        } else {
          _errorMessage = donationData['message'];
        }
      } else {
        _errorMessage = 'Gagal terhubung ke server.';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _takeDonation() async {
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
        Uri.parse('${widget.apiBaseUrl}/take_donations.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'donation_id': widget.donationId,
          'receiver_id': widget.receiverId,
        }),
      );

      Navigator.of(context).pop();

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Donasi berhasil diambil!')),
        );

        widget.onDonationTaken();
        Navigator.of(context).pop();
      } else {
        _showMessage('Gagal', data['message'] ?? 'Terjadi kesalahan.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showMessage('Error', 'Kesalahan jaringan: $e');
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
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Donasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, textAlign: TextAlign.center),
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dari Donatur:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: donatorDetails?['photo'] != null
                              ? NetworkImage('${widget.apiBaseUrl}/${donatorDetails!['photo']}')
                              : null,
                          child: donatorDetails?['photo'] == null ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            donatorDetails?['username'] ?? 'Nama Donatur',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.phone, 'No. Telepon', donatorDetails?['no_telp'] ?? '-'),

                        () {
                      final dynamic rawRating = donatorDetails?['rating'];
                      double ratingValue = 0.0;
                      if (rawRating is num) {
                        ratingValue = rawRating.toDouble();
                      } else if (rawRating is String) {
                        ratingValue = double.tryParse(rawRating) ?? 0.0;
                      }
                      return _buildDetailRow(Icons.star, 'Rating', ratingValue.toStringAsFixed(1));
                    }(),

                  ],
                ),
              ),
            ),

            const Divider(height: 30, thickness: 1),

            const Text("Detail Item Donasi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (donationItems.isEmpty)
              const Text('Tidak ada item yang terdaftar.'),

            ...donationItems.map((item) {
              String? imageUrlFront = (item['front_photo_url'] != null && item['front_photo_url'] != '') ? '${widget.apiBaseUrl}/${item['front_photo_url']}' : null;
              String? imageUrlBack = (item['back_photo_url'] != null && item['back_photo_url'] != '') ? '${widget.apiBaseUrl}/${item['back_photo_url']}' : null;

              String itemNameOrType = donationDetails!['type'] == 'pakaian'
                  ? (item['clothing_type'] ?? 'Pakaian')
                  : (item['item_name'] ?? 'Barang');

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemNameOrType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Ukuran: ${item['size'] ?? '-'}'),
                      Text('Kekurangan: ${item['defects'] ?? 'Tidak ada'}'),
                      const SizedBox(height: 10),
                      if (imageUrlFront != null) _buildImageDisplay('Foto Depan', imageUrlFront),
                      if (imageUrlBack != null) _buildImageDisplay('Foto Belakang', imageUrlBack),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: (donationDetails?['status_donasi'] == 'Diterima')
                    ? null
                    : _showConfirmationDialog,
                icon: const Icon(Icons.shopping_basket,color: Colors.white),
                label: Text(
                  (donationDetails?['status_donasi'] == 'Diterima')
                      ? 'Donasi Telah Diambil'
                      : 'Ambil Donasi Ini',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (donationDetails?['status_donasi'] == 'Diterima')
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin mengambil donasi ini? Proses ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _takeDonation();
            },
            child: const Text('Ya, Ambil'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        Center(
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}