import 'package:flutter/material.dart';
import 'donation_form_screen.dart';

class DonationTypeSelectionScreen extends StatelessWidget {
  final int userId;
  const DonationTypeSelectionScreen({super.key, required this.userId});

  Widget _buildDonationOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    required Gradient iconGradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: iconGradient,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Colors.orange.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mulai Donasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Image.network(
              'https://ouch-cdn2.icons8.com/s-v_f2s4T4V2d_J_e-n2K_H2wD22-aLe-D_i4kS-c3M/rs:fit:368:368/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvNDE5/LzA1ZDY4MDY3LWY0/MzgtNDg0MC1iODVj/LWEzYWYxZTBlZDM4/Ny5wbmc.png',
              height: 180,
              errorBuilder: (c, e, s) => const SizedBox(height: 180, child: Icon(Icons.volunteer_activism, size: 100, color: Colors.grey)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Apa yang ingin Anda donasikan?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Pilih salah satu jenis donasi di bawah ini untuk melanjutkan ke formulir pengisian.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),

          _buildDonationOptionCard(
            context: context,
            icon: Icons.checkroom_outlined,
            title: 'Pakaian Layak Pakai',
            description: 'Baju, celana, dan lainnya.',
            iconColor: primaryColor,
            iconGradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.8), primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () async {

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationFormScreen(donationType: 'pakaian', userId: userId),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          const SizedBox(height: 20),

          _buildDonationOptionCard(
            context: context,
            icon: Icons.widgets_outlined,
            title: 'Barang Bekas',
            description: 'Peralatan, buku, dll.',
            iconColor: secondaryColor,
            iconGradient: LinearGradient(
              colors: [secondaryColor.withOpacity(0.8), secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationFormScreen(donationType: 'barang', userId: userId),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }
}
