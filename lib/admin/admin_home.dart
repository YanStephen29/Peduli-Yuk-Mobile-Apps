import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ArticleDetailPage.dart';
import 'admin_donation_detail_screen.dart';
import 'dart:async';

class AdminHomePage extends StatefulWidget {
  final String apiBaseUrl;
  final int adminId;
  const AdminHomePage({Key? key, required this.apiBaseUrl, required this.adminId}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  List<dynamic> articles = [];
  List<dynamic> pendingDonations = [];
  bool _isLoadingPendingDonations = false;
  Map<String, dynamic>? adminProfile;
  List<String> newDonationUsernames = [];
  bool _showNotificationBanner = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  List<int> _newDonationIdsForBlink = [];

  @override
  void initState() {
    super.initState();
    fetchArticles();
    fetchAdminProfile();
    fetchPendingDonations();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController);
    int blinkCount = 0;
    _blinkController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        blinkCount++;
        if (blinkCount < 3) {
          _blinkController.reverse();
        } else {
          _blinkController.stop();
          _newDonationIdsForBlink.clear();
          _showNotificationBanner = false;
          setState(() {});
        }
      } else if (status == AnimationStatus.dismissed) {
        _blinkController.forward();
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> fetchArticles() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_articles.php'));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          articles = data['articles'];
        });
      }
    } catch (e) {
      print('Error fetching articles: $e');
    }
  }

  Future<void> fetchAdminProfile() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_admin_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'admin_id': widget.adminId}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          adminProfile = data['admin'];
        });
      } else {
        print('Failed to load admin profile: ${data['message']}');
      }
    } catch (e) {
      print('Error fetching admin profile: $e');
    }
  }

  Future<void> fetchPendingDonations() async {
    setState(() {
      _isLoadingPendingDonations = true;
    });
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_pending_donations.php'));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        List<dynamic> fetchedDonations = data['pending_donations'];
        final newDonationsResponse = await http.get(Uri.parse('${widget.apiBaseUrl}/check_new_donations.php'));
        final newDonationsData = json.decode(newDonationsResponse.body);

        if (newDonationsResponse.statusCode == 200 && newDonationsData['status'] == 'success') {
          List<dynamic> newDonations = newDonationsData['new_donations'];
          if (newDonations.isNotEmpty) {
            newDonationUsernames.clear();
            _newDonationIdsForBlink.clear();
            for (var nd in newDonations) {
              newDonationUsernames.add(nd['username']);
              _newDonationIdsForBlink.add(int.parse(nd['donation_id'].toString()));
            }
            _showNotificationBanner = true;
            _blinkController.forward(from: 0.0);
          } else {
            _showNotificationBanner = false;
          }
        }
        setState(() {
          pendingDonations = fetchedDonations;
        });
      } else {
        print('Failed to load pending donations: ${data['message']}');
      }
    } catch (e) {
      print('Error fetching pending donations: $e');
    } finally {
      if(mounted) {
        setState(() {
          _isLoadingPendingDonations = false;
        });
      }
    }
  }

  Future<void> markDonationsAsSeen(List<int> donationIds) async {
    if (donationIds.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/mark_donations_as_seen.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'donation_ids': donationIds}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        print(data['message']);
        fetchPendingDonations();
      } else {
        print('Failed to mark donations as seen: ${data['message']}');
      }
    } catch (e) {
      print('Error marking donations as seen: $e');
    }
  }

  Future<void> deleteArticle(int id) async {
    final response = await http.post(
      Uri.parse('${widget.apiBaseUrl}/delete.php'),
      body: {'id': id.toString()},
    );

    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Artikel berhasil dihapus")));
      fetchArticles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus artikel")));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0, bottom: 12.0, left: 4.0, right: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor.withOpacity(0.9), Theme.of(context).primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withOpacity(0.9),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: adminProfile?['photo'] != null && adminProfile!['photo'] != ''
                    ? NetworkImage('${widget.apiBaseUrl}/${adminProfile!['photo']}') as ImageProvider
                    : const AssetImage('assets/images/logo.png') as ImageProvider,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
                  ),
                  Text(
                    adminProfile?['username'] ?? 'Admin',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ArticleDetailPage(apiBaseUrl: widget.apiBaseUrl, article: article, adminId: widget.adminId),
            ));
          },
          child: Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: article['image_url'] != ''
                    ? Image.network('${widget.apiBaseUrl}/${article['image_url']}', fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 50))))
                    : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 50))),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          stops: const [0.0, 0.8]
                      )
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  article['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationTile(Map<String, dynamic> donation) {
    final isNewDonation = _newDonationIdsForBlink.contains(int.parse(donation['donation_id'].toString()));
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: isNewDonation ? _blinkAnimation.value : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (isNewDonation) {
                  await markDonationsAsSeen([int.parse(donation['donation_id'].toString())]);
                }
                await Navigator.push(context, MaterialPageRoute(
                  builder: (context) => AdminDonationDetailScreen(
                    apiBaseUrl: widget.apiBaseUrl,
                    donationId: int.parse(donation['donation_id'].toString()),
                    onUpdate: fetchPendingDonations,
                  ),
                ));
                fetchPendingDonations();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: donation['user_photo_url'] != null && donation['user_photo_url'] != ''
                        ? NetworkImage('${widget.apiBaseUrl}/${donation['user_photo_url']}') as ImageProvider
                        : const AssetImage('assets/images/logo.png') as ImageProvider,
                  ),
                  title: Text(donation['username'] ?? 'Pengguna', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Jenis: ${donation['donation_type'].toString().toUpperCase()}', style: TextStyle(color: Colors.grey.shade700)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([fetchArticles(), fetchAdminProfile(), fetchPendingDonations()]);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showNotificationBanner && newDonationUsernames.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ada permintaan verifikasi baru dari ${newDonationUsernames.join(', ')}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800, // Warna teks lebih gelap
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                      onPressed: () {
                        setState(() {
                          _showNotificationBanner = false;
                          _blinkController.stop();
                          _newDonationIdsForBlink.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

            _buildProfileHeader(),

            _buildSectionTitle('Artikel Terbaru'),
            SizedBox(
              height: 190,
              child: articles.isEmpty
                  ? const Center(child: Text("Belum ada artikel."))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                itemBuilder: (context, index) => _buildArticleCard(articles[index]),
              ),
            ),

            _buildSectionTitle('Permintaan Donasi Baru'),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: _isLoadingPendingDonations
                  ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                  : pendingDonations.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                child: Center(child: Text('Tidak ada permintaan donasi baru.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600))),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingDonations.length,
                itemBuilder: (context, index) => _buildDonationTile(pendingDonations[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}