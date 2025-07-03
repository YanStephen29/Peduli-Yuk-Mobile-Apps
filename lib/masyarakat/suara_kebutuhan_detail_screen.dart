import 'package:flutter/material.dart';

class SuaraKebutuhanDetailScreen extends StatelessWidget {
  final String apiBaseUrl;
  final Map<String, dynamic> suaraKebutuhan;

  const SuaraKebutuhanDetailScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.suaraKebutuhan,
  }) : super(key: key);

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
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
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(context, Icons.calendar_today_outlined, 'Dibuat', suaraKebutuhan['created_at'] ?? 'N/A'),
            ),
            SizedBox(
              height: 40,
              child: VerticalDivider(color: Colors.grey.shade300),
            ),
            Expanded(
              child: _buildStatItem(context, Icons.timer_outlined, 'Batas Waktu', suaraKebutuhan['deadline'] ?? 'N/A', isHighlighted: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label, String value, {bool isHighlighted = false}) {
    final color = isHighlighted ? Theme.of(context).primaryColor : Colors.grey.shade700;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = suaraKebutuhan['image_url'] != null && suaraKebutuhan['image_url'] != ''
        ? '$apiBaseUrl/${suaraKebutuhan['image_url']}'
        : '';
    final String creatorRole = suaraKebutuhan['role'] ?? 'Tidak Diketahui';
    final String organizationName = suaraKebutuhan['organization_name'] ?? 'N/A';
    final String address = suaraKebutuhan['address'] ?? 'N/A';

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
              background: imageUrl.isNotEmpty
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
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  suaraKebutuhan['title'] ?? 'Judul Tidak Tersedia',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),

                _buildStatsCard(context),
                _buildSectionHeader(context, 'Deskripsi'),
                Text(
                  suaraKebutuhan['description'] ?? 'Deskripsi tidak tersedia.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.grey.shade800),
                  textAlign: TextAlign.justify,
                ),

                _buildSectionHeader(context, 'Informasi Pembuat'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(context, Icons.business_outlined, 'Organisasi', organizationName),
                        const Divider(),
                        _buildInfoRow(context, Icons.badge_outlined, 'Peran', creatorRole),
                        const Divider(),
                        _buildInfoRow(context, Icons.location_on_outlined, 'Alamat', address),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
