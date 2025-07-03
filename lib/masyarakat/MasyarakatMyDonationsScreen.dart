import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'donation_type_selection_screen.dart';
import 'donation_detail_screen.dart';

class MasyarakatMyDonationsScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;

  const MasyarakatMyDonationsScreen({Key? key, required this.apiBaseUrl, required this.userId}) : super(key: key);

  @override
  State<MasyarakatMyDonationsScreen> createState() => _MasyarakatMyDonationsScreenState();
}

class _MasyarakatMyDonationsScreenState extends State<MasyarakatMyDonationsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> myDonations = [];
  bool _isLoadingDonations = true;

  late AnimationController _fabAnimationController;
  late Animation<Offset> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fetchMyDonations();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFabAnimation();
      _fabAnimationController.forward();
    });
  }

  void _setupFabAnimation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final beginOffset = Offset((screenWidth / 2) - 28, 0);
    final endOffset = Offset(screenWidth - 56 - 16, 0);

    _fabAnimation = Tween<Offset>(
      begin: beginOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyDonations() async {
    if(!mounted) return;
    setState(() {
      _isLoadingDonations = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_my_donations.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            myDonations = data['donations'];
          });
        } else {
          _showMessage('Error', data['message'] ?? 'Gagal mengambil donasi Anda.');
        }
      } else if (mounted) {
        _showMessage('Error', 'Gagal terhubung ke server: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) _showMessage('Error', 'Terjadi kesalahan jaringan: $e');
      print('Error fetching my donations: $e');
    } finally {
      if(mounted) {
        setState(() {
          _isLoadingDonations = false;
        });
      }
    }
  }

  void _showMessage(String title, String message) {
    // ... Logika Anda tidak diubah ...
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
    // ... Logika Anda tidak diubah ...
    switch (type) {
      case 'kaos': return 'Kaos';
      case 'kemeja': return 'Kemeja';
      case 'celana': return 'Celana';
      case 'pakaian_dalam': return 'Pakaian Dalam';
      case 'lainnya': return 'Lainnya';
      default: return type;
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
      body: Stack(
        children: [
          _isLoadingDonations
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _fetchMyDonations,
            child: myDonations.isEmpty
                ? _buildEmptyState()
                : _buildDonationList(),
          ),
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {

              if (_fabAnimationController.isAnimating || _fabAnimationController.isCompleted) {
                return Positioned(
                  left: _fabAnimation.value.dx,
                  bottom: 16.0,
                  child: child!,
                );
              }
              return const SizedBox.shrink();
            },
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DonationTypeSelectionScreen(userId: widget.userId),
                  ),
                );
                _fetchMyDonations();
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
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
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Anda Belum Berdonasi',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semua donasi yang sedang berlangsung akan muncul di sini. Tekan tombol + untuk memulai.',
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
    );
  }

  Widget _buildDonationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: myDonations.length,
      itemBuilder: (context, index) {
        final donation = myDonations[index];
        return _buildDonationCard(donation);
      },
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    String? imageUrl;
    String itemName = 'Donasi ID: #${donation['id']}';
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationDetailScreen(
                apiBaseUrl: widget.apiBaseUrl,
                donationId: int.parse(donation['id'].toString()),
              ),
            ),
          ).then((_) => _fetchMyDonations());
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
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)))
                      : Container(color: Colors.grey.shade200, child: Icon(Icons.redeem, color: Colors.grey.shade400)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('ID: #${donation['id']} • ${donation['created_at']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(donation['status'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      backgroundColor: _getStatusColor(donation['status']),
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