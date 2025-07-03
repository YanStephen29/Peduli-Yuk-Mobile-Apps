import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peduliyuk_api/navigation/navbar_organization.dart';
import 'package:peduliyuk_api/organization/organization_home_page.dart';
import 'package:peduliyuk_api/organization/suara_kebutuhan_list_screen.dart';
import 'package:peduliyuk_api/organization/penerimaan_screen.dart';
import 'package:peduliyuk_api/organization/profile_screen.dart';
import 'package:peduliyuk_api/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrganizationMainScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const OrganizationMainScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
  }) : super(key: key);
  @override
  State<OrganizationMainScreen> createState() => _OrganizationMainScreenState();
}

class _OrganizationMainScreenState extends State<OrganizationMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final GlobalKey<OrganizationHomePageState> _homePageKey = GlobalKey<OrganizationHomePageState>();

  final List<String> appBarTitles = const [
    'Beranda',
    'Suara Kebutuhan',
    'Penerimaan',
    'Profil',
  ];

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    pages = [
      OrganizationHomePage(key: _homePageKey, apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
      SuaraKebutuhanListScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId),
      PenerimaanScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId, onRefreshMainScreen: _refreshHomePageData),
      ProfileScreen(apiBaseUrl: widget.apiBaseUrl, userId: widget.userId, onLogout: _logout),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refreshHomePageData() {
    _homePageKey.currentState?.fetchInitialData();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage(apiBaseUrl: widget.apiBaseUrl)),
            (Route<dynamic> route) => false,
      );
    }
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
      bottomNavigationBar: NavbarOrganization(
        currentIndex: _currentIndex,
        onTap: _onNavbarTap,
      ),
    );
  }
}