import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/masyarakat/masyarakat_main_screen.dart';
import 'package:peduliyuk_api/controller/admin_main_screen.dart';
import 'package:peduliyuk_api/organization/organization_main_screen.dart';

class LoginPage extends StatefulWidget {
  final String apiBaseUrl;

  const LoginPage({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailOrUsernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> submitLogin() async {
    if (emailOrUsernameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email/Username dan Password tidak boleh kosong.")),
      );
      return;
    }

    var body = {
      'email_or_username': emailOrUsernameController.text,
      'password': passwordController.text,
    };

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/login.php'),
        body: body,
      );

      if (mounted) Navigator.pop(context);

      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        String role = jsonData['role'];
        final int userId = jsonData['user_id'];

        if (!mounted) return;

        if (role == 'masyarakat') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MasyarakatMainScreen(apiBaseUrl: widget.apiBaseUrl, userId: userId)),
          );
        } else if (role == 'lembaga_sosial' || role == 'umkm') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OrganizationMainScreen(apiBaseUrl: widget.apiBaseUrl, userId: userId)),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMainScreen(apiBaseUrl: widget.apiBaseUrl, adminId: userId),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? "Login gagal.")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan koneksi: $e")),
      );
      print('Login Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [

              const SizedBox(height: 20),

              Image.asset(
                'assets/logo.png',
                height: 180,
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang Kembali!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk untuk melanjutkan ke Peduli Yuk',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: emailOrUsernameController,
                        decoration: InputDecoration(
                          labelText: 'Email atau Username',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitLogin,
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}