import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peduliyuk_api/navigation/navbar_masyarakat.dart';
import 'package:peduliyuk_api/masyarakat/masyarakat_home_page.dart';
import 'package:peduliyuk_api/masyarakat/MasyarakatMyDonationsScreen.dart';
import 'package:peduliyuk_api/masyarakat/MasyarakatDonationHistoryScreen.dart';
import 'package:peduliyuk_api/masyarakat/MasyarakatProfileScreen.dart';
import 'package:peduliyuk_api/masyarakat/donation_type_selection_screen.dart';

class MasyarakatMainScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const MasyarakatMainScreen({Key? key, required this.apiBaseUrl, required this.userId}) : super(key: key);

  @override
  _MasyarakatMainScreenState createState() => _MasyarakatMainScreenState();
}

class _MasyarakatMainScreenState extends State<MasyarakatMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<String> appBarTitles = const [
    'Beranda',
    'Donasi Saya',
    'Riwayat Donasi',
    'Profil Saya',
  ];
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    pages = [
      MasyarakatHomePage(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
      MasyarakatMyDonationsScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
      MasyarakatDonationHistoryScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
      MasyarakatProfileScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavbarTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            appBarTitles[_currentIndex],
            key: ValueKey<String>(appBarTitles[_currentIndex]),
            style: GoogleFonts.poppins(
              color: Colors.green[800],
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 1
          ? null
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DonationTypeSelectionScreen(
                userId: widget.userId,
              ),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        height: 65,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: NavbarMasyarakat(
                currentIndex: _currentIndex,
                onTap: _onNavbarTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}