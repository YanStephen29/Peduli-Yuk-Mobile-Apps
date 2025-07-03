import 'package:flutter/material.dart';
import 'package:peduliyuk_api/pages/register.dart';
import 'package:peduliyuk_api/pages/login.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final String apiBaseUrl = 'http://192.168.64.247/peduliyuk_api';

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.green.shade700;
    final Color accentGreen = Colors.green.shade400;

    return MaterialApp(
      title: 'Peduli Yuk!',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: primaryGreen,

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey.shade800),
          titleTextStyle: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'
            ),
          ),
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: accentGreen,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(apiBaseUrl: apiBaseUrl),
        '/register': (context) => SignupPage(apiBaseUrl: apiBaseUrl),
        '/login': (context) => LoginPage(apiBaseUrl: apiBaseUrl),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}


class HomePage extends StatelessWidget {
  final String apiBaseUrl;
  const HomePage({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 250,
              ),
              const SizedBox(height: 60),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Daftar'),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}