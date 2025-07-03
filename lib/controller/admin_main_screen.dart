import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peduliyuk_api/admin/admin_home.dart';
import 'package:peduliyuk_api/controller/article_admin.dart';
import 'package:peduliyuk_api/controller/profile_admin.dart';
import 'package:peduliyuk_api/navigation/navbar_admin.dart';
import 'package:peduliyuk_api/admin/add_article.dart';

const Key adminMainScreenKey = Key('AdminMainScreen');

class AdminMainScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int adminId;
  const AdminMainScreen({Key? key, required this.apiBaseUrl, required this.adminId}) : super(key: key);

  @override
  _AdminMainScreenState createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  late final List<Widget> pages;
  final List<String> appBarTitles = const [
    'Home',
    'Artikel',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    pages = [
      AdminHomePage(apiBaseUrl: widget.apiBaseUrl, adminId: widget.adminId),
      ArtikelAdminPage(apiBaseUrl: widget.apiBaseUrl, adminId: widget.adminId),
      ProfileAdminPage(apiBaseUrl: widget.apiBaseUrl, adminId: widget.adminId),
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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: adminMainScreenKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          appBarTitles[_currentIndex],
          style: GoogleFonts.poppins(
            color: Colors.green[800],
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: pages,
      ),
      bottomNavigationBar: NavbarAdmin(
        currentIndex: _currentIndex,
        onTap: _onNavbarTap,
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(child: child, scale: animation);
        },
        child: _currentIndex == 1
            ? FloatingActionButton(
          key: const ValueKey('fab_add_article'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddArticlePage(
                  apiBaseUrl: widget.apiBaseUrl,
                  adminId: widget.adminId,
                ),
              ),
            ).then((_) {
              setState(() {});
            });
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        )
            : const SizedBox.shrink(key: ValueKey('fab_empty')),
      ),
    );
  }
}