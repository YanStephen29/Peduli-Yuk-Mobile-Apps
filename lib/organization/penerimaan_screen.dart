import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/organization/donation_detail_accepted_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart' as rating_bar;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class PenerimaanScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  final VoidCallback onRefreshMainScreen;

  const PenerimaanScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
    required this.onRefreshMainScreen,
  }) : super(key: key);

  @override
  State<PenerimaanScreen> createState() => _PenerimaanScreenState();
}

class _PenerimaanScreenState extends State<PenerimaanScreen> with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color greyText = Color(0xFF616161);
  static const Color accentOrange = Color(0xFFFFC107);
  static const Color accentIndigo = Color(0xFF3F51B5);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF009688);

  late TabController _tabController;
  List<dynamic> _ongoingDonations = [];
  List<dynamic> _completedDonations = [];
  bool _isLoadingOngoing = true;
  bool _isLoadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDonations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonations() async {
    await Future.wait([
      _fetchOngoingDonations(),
      _fetchCompletedDonations(),
    ]);
  }

  Future<void> _fetchOngoingDonations() async {
    if (!mounted) return;
    setState(() => _isLoadingOngoing = true);
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_user_accepted_donations.php?receiver_id=${widget.userId}'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ongoingDonations = (data['status'] == 'success') ? data['donations'] : [];
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingOngoing = false);
    }
  }

  Future<void> _fetchCompletedDonations() async {
    if (!mounted) return;
    setState(() => _isLoadingCompleted = true);
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_user_completed_donations.php?receiver_id=${widget.userId}'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _completedDonations = (data['status'] == 'success') ? data['donations'] : [];
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingCompleted = false);
    }
  }

  Future<void> _navigateToDetailScreen(int donationAcceptanceId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailAcceptedScreen(
          apiBaseUrl: widget.apiBaseUrl,
          donationAcceptanceId: donationAcceptanceId,
          receiverId: widget.userId,
          onRefreshParent: () {
            _fetchOngoingDonations();
            widget.onRefreshMainScreen();
          },
        ),
      ),
    );

    if (result == true) {
      _fetchDonations();
      widget.onRefreshMainScreen();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Waiting For Approval': return accentOrange;
      case 'Waiting For Receiver': return primaryGreen;
      case 'Found Receiver': return accentIndigo;
      case 'On Delivery': return accentPurple;
      case 'Received': return lightGreen;
      case 'Waiting For Feedback': return accentTeal;
      case 'Success': return darkGreen;
      default: return greyText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Waiting For Approval': return Icons.pending_actions_outlined;
      case 'Waiting For Receiver': return Icons.search_outlined;
      case 'Found Receiver': return Icons.check_circle_outline;
      case 'On Delivery': return Icons.delivery_dining_outlined;
      case 'Received': return Icons.done_all;
      case 'Waiting For Feedback': return Icons.rate_review_outlined;
      case 'Success': return Icons.task_alt;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryLightGreen,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: primaryGreen,
                unselectedLabelColor: greyText,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3.0, color: lightGreen),
                  insets: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                tabs: const [
                  Tab(text: 'Sedang Berjalan'),
                  Tab(text: 'Selesai'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDonationList(
                    donations: _ongoingDonations,
                    isLoading: _isLoadingOngoing,
                    onRefresh: _fetchOngoingDonations,
                    emptyMessage: 'Tidak ada donasi yang sedang berjalan.',
                    isOngoing: true,
                  ),
                  _buildDonationList(
                    donations: _completedDonations,
                    isLoading: _isLoadingCompleted,
                    onRefresh: _fetchCompletedDonations,
                    emptyMessage: 'Belum ada donasi yang telah selesai.',
                    isOngoing: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationList({
    required List<dynamic> donations,
    required bool isLoading,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    required bool isOngoing,
  }) {
    if (isLoading) {
      return _ShimmerLoadingList();
    }
    if (donations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: greyText.withOpacity(0.7), size: 80),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: greyText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        itemCount: donations.length,
        itemBuilder: (context, index) {
          final donation = donations[index];
          return _DonationCard(
            donation: donation,
            apiBaseUrl: widget.apiBaseUrl,
            isOngoing: isOngoing,
            onTap: isOngoing ? () => _navigateToDetailScreen(int.parse(donation['id'])) : null,
            getStatusColor: _getStatusColor,
            getStatusIcon: _getStatusIcon,
          );
        },
      ),
    );
  }
}


class _DonationCard extends StatelessWidget {
  final dynamic donation;
  final String apiBaseUrl;
  final bool isOngoing;
  final VoidCallback? onTap;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;

  const _DonationCard({
    Key? key,
    required this.donation,
    required this.apiBaseUrl,
    required this.isOngoing,
    this.onTap,
    required this.getStatusColor,
    required this.getStatusIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parsing data
    final donorUsername = donation['donor_username']?.toString() ?? 'Pengguna Anonim';
    final donorPhotoUrl = donation['donor_photo'] != null && donation['donor_photo'] != ''
        ? '$apiBaseUrl/${donation['donor_photo']}'
        : null;
    final donationAcceptanceId = int.tryParse(donation['id']?.toString() ?? '0') ?? 0;
    final donationStatus = donation['status']?.toString() ?? 'Tidak Diketahui';
    final statusColor = getStatusColor(donationStatus);
    final statusIcon = getStatusIcon(donationStatus);
    final donationType = donation['donation_type']?.toString().toUpperCase() ?? 'DONASI';
    final totalQuantity = donation['total_quantity']?.toString() ?? '0';

    final DateTime? pengambilanDate = DateTime.tryParse(donation['tanggal_pengambilan'] ?? '');
    final String tanggalPengambilan = pengambilanDate != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(pengambilanDate)
        : 'Belum ditentukan';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: _PenerimaanScreenState.primaryGreen,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: _PenerimaanScreenState.primaryGreen.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _PenerimaanScreenState.lightGreen.withOpacity(0.2),
                    backgroundImage: donorPhotoUrl != null ? NetworkImage(donorPhotoUrl) : null,
                    child: donorPhotoUrl == null ? Icon(Icons.person, size: 30, color: _PenerimaanScreenState.darkGreen.withOpacity(0.6)) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donorUsername,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _PenerimaanScreenState.darkGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $donationAcceptanceId',
                          style: TextStyle(fontSize: 13, color: _PenerimaanScreenState.greyText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          donationStatus,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.category_outlined,
                '$donationType ($totalQuantity item)',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.event_available_outlined,
                'Pengambilan: $tanggalPengambilan',
              ),
              if (!isOngoing) ...[
                const SizedBox(height: 12),
                _buildCompletedInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _PenerimaanScreenState.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: _PenerimaanScreenState.greyText, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedInfo(BuildContext context) {
    final rating = double.tryParse(donation['rating']?.toString() ?? '0') ?? 0.0;
    final feedbackComment = donation['feedback_comment']?.toString() ?? '';

    if (rating == 0.0 && feedbackComment.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _PenerimaanScreenState.darkGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rating > 0)
            Row(
              children: [
                const Text('Rating:', style: TextStyle(fontSize: 14, color: _PenerimaanScreenState.greyText)),
                const SizedBox(width: 8),
                rating_bar.RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 18.0,
                ),
              ],
            ),
          if (rating > 0 && feedbackComment.isNotEmpty) const SizedBox(height: 8),
          if (feedbackComment.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, color: _PenerimaanScreenState.greyText, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"$feedbackComment"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: _PenerimaanScreenState.darkGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ShimmerLoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 150, height: 18, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(width: 100, height: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Container(width: double.infinity, height: 16, color: Colors.white),
                const SizedBox(height: 12),
                Container(width: 200, height: 16, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}