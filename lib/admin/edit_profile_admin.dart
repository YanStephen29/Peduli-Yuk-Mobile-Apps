import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileAdminPage extends StatefulWidget {
  final String apiBaseUrl;
  final Map<String, dynamic> adminData;
  final int adminId;

  const EditProfileAdminPage({
    Key? key,
    required this.apiBaseUrl,
    required this.adminData,
    required this.adminId,
  }) : super(key: key);

  @override
  _EditProfileAdminPageState createState() => _EditProfileAdminPageState();
}

class _EditProfileAdminPageState extends State<EditProfileAdminPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  File? _imageFile;
  String? _currentPhotoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.adminData['username'] ?? '';
    _noTelpController.text = widget.adminData['no_telp'] ?? '';
    _currentPhotoUrl = widget.adminData['photo'];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _noTelpController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentPhotoUrl = null;
      });
    }
  }

  Future<void> updateAdminProfile() async {
    if (widget.adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Admin tidak ditemukan. Tidak bisa update.')),
      );
      return;
    }
    setState(() => _isSaving = true);

    var request = http.MultipartRequest('POST', Uri.parse('${widget.apiBaseUrl}/update_admin_profile.php'));
    request.fields['id'] = widget.adminId.toString();
    request.fields['username'] = _usernameController.text;
    request.fields['no_telp'] = _noTelpController.text;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));
      request.fields['photo_action'] = 'upload_new';
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      request.fields['photo_action'] = 'keep_existing';
      request.fields['existing_photo_url'] = _currentPhotoUrl!;
    } else {
      request.fields['photo_action'] = 'clear_photo';
    }

    try {
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if(!mounted) return;
      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil admin berhasil diperbarui!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: ${data['message'] ?? 'Unknown error'}')));
      }
    } catch (e) {
      print('Exception updating admin profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan saat memperbarui profil: $e')));
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                        ? NetworkImage('${widget.apiBaseUrl}/$_currentPhotoUrl')
                        : const AssetImage('assets/images/logo.png')) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Theme.of(context).primaryColor,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: pickImage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: _usernameController,
              decoration: _buildInputDecoration('Username', Icons.person_outline),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noTelpController,
              decoration: _buildInputDecoration('Nomor Telepon', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : updateAdminProfile, // Logika loading tetap sama
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}