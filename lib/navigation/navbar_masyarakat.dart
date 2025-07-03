import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavbarMasyarakat extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavbarMasyarakat({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  Widget _buildActiveIcon(BuildContext context, IconData iconData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Icon(iconData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color unselectedColor = Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          onTap(index);
        },

        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: primaryColor,
        unselectedItemColor: unselectedColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),

        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: _buildActiveIcon(context, Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.redeem_outlined), // Ikon baru: kotak kado/donasi
            activeIcon: _buildActiveIcon(context, Icons.redeem), // Ikon baru (filled)
            label: 'Donasi Saya', // Label baru
          ),

          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: _buildActiveIcon(context, Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: _buildActiveIcon(context, Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
