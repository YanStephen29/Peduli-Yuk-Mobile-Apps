import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  final String apiBaseUrl;

  const SignupPage({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  String role = 'masyarakat';
  bool isSecondStep = false;
  bool _isPasswordVisible = false;

  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController organizationNameController = TextEditingController();
  int? selectedPositionId;
  List<dynamic> positions = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPositions();
  }

  Future<void> fetchPositions() async {
    try {
      final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_positions.php'));
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          positions = jsonData['positions'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil data posisi")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan mengambil data posisi")),
      );
    }
  }

  void goToSecondStep() {
    if (!_validateFirstStep()) return;
    setState(() {
      isSecondStep = true;
    });
  }

  bool _validateFirstStep() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        usernameController.text.isEmpty ||
        noTelpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Semua input pada langkah 1 wajib diisi")));
      return false;
    }
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Format email tidak valid")));
      return false;
    }
    return true;
  }

  bool _validateSecondStep() {
    if (role == 'masyarakat') {
      if (ageController.text.isEmpty || addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Usia dan alamat wajib diisi")));
        return false;
      }
      if (int.tryParse(ageController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Usia harus berupa angka")));
        return false;
      }
    } else {
      if (organizationNameController.text.isEmpty || addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Nama organisasi dan alamat wajib diisi")));
        return false;
      }
      if (selectedPositionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Posisi harus dipilih")));
        return false;
      }
    }
    return true;
  }

  Future<void> submitSignup() async {
    if (!_validateSecondStep()) return;
    setState(() {
      isLoading = true;
    });

    Map<String, String> body = {
      'email': emailController.text,
      'password': passwordController.text,
      'role': role,
      'username': usernameController.text,
      'no_telp': noTelpController.text,
    };

    if (role == 'masyarakat') {
      body['age'] = ageController.text;
      body['address'] = addressController.text;
    } else {
      body['organization_name'] = organizationNameController.text;
      body['address'] = addressController.text;
      body['position_id'] = selectedPositionId.toString();
    }

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/signup.php'),
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Pendaftaran berhasil, silakan login")));
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonData['message'] ?? "Terjadi kesalahan")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal terhubung ke server")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buat Akun Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Langkah 1: Informasi Akun', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        SizedBox(height: 32),
        TextFormField(controller: emailController, decoration: _buildInputDecoration('Email', Icons.email_outlined), keyboardType: TextInputType.emailAddress),
        SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: !_isPasswordVisible,
          decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(controller: usernameController, decoration: _buildInputDecoration('Username', Icons.person_outline)),
        SizedBox(height: 16),
        TextFormField(controller: noTelpController, decoration: _buildInputDecoration('No. Telepon', Icons.phone_outlined), keyboardType: TextInputType.phone),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: _buildInputDecoration('Daftar sebagai', Icons.groups_outlined),
          value: role,
          items: ['masyarakat', 'lembaga_sosial', 'umkm']
              .map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1).replaceAll('_', ' '))))
              .toList(),
          onChanged: (value) => setState(() => role = value!),
        ),
        SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: goToSecondStep, child: Text('Lanjutkan')),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    bool isMasyarakat = role == 'masyarakat';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isMasyarakat ? 'Profil Masyarakat' : 'Profil Organisasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('Langkah 2: Lengkapi Data Diri', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
        SizedBox(height: 32),

        if (isMasyarakat) ...[
          TextFormField(controller: ageController, decoration: _buildInputDecoration('Usia', Icons.cake_outlined), keyboardType: TextInputType.number),
        ] else ...[
          TextFormField(controller: organizationNameController, decoration: _buildInputDecoration('Nama Organisasi', Icons.business_outlined)),
          SizedBox(height: 16),
          DropdownButtonFormField<int>(
            decoration: _buildInputDecoration('Posisi dalam Organisasi', Icons.work_outline),
            value: selectedPositionId,
            items: positions.map<DropdownMenuItem<int>>((pos) => DropdownMenuItem<int>(value: pos['id'], child: Text(pos['name']))).toList(),
            onChanged: (value) => setState(() => selectedPositionId = value),
            isExpanded: true,
          ),
        ],

        SizedBox(height: 16),
        TextFormField(
          controller: addressController,
          decoration: _buildInputDecoration('Alamat Lengkap', Icons.location_on_outlined),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
        ),
        SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : submitSignup,
            child: isLoading ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text('Daftar'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun'),
        leading: isSecondStep
            ? IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => isSecondStep = false),
        )
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              Image.asset('assets/logo.png', height: 150), // Pastikan path logo benar
              SizedBox(height: 20),
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isSecondStep ? _buildStep2() : _buildStep1(),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}