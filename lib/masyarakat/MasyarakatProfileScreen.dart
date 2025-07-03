import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class MasyarakatProfileScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const MasyarakatProfileScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
  }) : super(key: key);

  @override
  State<MasyarakatProfileScreen> createState() =>
      _MasyarakatProfileScreenState();
}

class _MasyarakatProfileScreenState extends State<MasyarakatProfileScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color softShadow = Color(0x222E7D32);
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color cardBackgroundColor = Color(0xFFF8F9FA);

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditMode = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    if(!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_user_profile.php'),
        body: {'user_id': widget.userId.toString()},
      );
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _userData = data['user_data'];
            _updateControllers();
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Gagal memuat profil.');
        }
      } else if (mounted) {
        setState(() => _errorMessage = 'Kesalahan server: ${response.statusCode}');
      }
    } catch (e) {
      if(mounted) setState(() => _errorMessage = 'Kesalahan jaringan: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers() {
    if (_userData != null) {
      _usernameController.text = _userData!['username'] ?? '';
      _addressController.text = _userData!['address'] ?? '';
      _phoneNumberController.text = _userData!['no_telp'] ?? '';
      _ageController.text = (_userData!['age'] ?? '').toString();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      _showMessage('Error', 'Gagal memilih gambar: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateProfile() async {
    if(!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [ CircularProgressIndicator(), SizedBox(height: 16), Text("Memperbarui profil...") ],
          ),
        );
      },
    );

    try {
      var uri = Uri.parse('${widget.apiBaseUrl}/update_user_profile.php');
      var request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = widget.userId.toString()
        ..fields['username'] = _usernameController.text
        ..fields['address'] = _addressController.text
        ..fields['no_telp'] = _phoneNumberController.text
        ..fields['age'] = _ageController.text;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));
      }
      var response = await request.send();
      if(!mounted) return;
      Navigator.pop(context);
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        if (data['status'] == 'success') {
          _showMessage('Berhasil', 'Profil berhasil diperbarui!');
          setState(() {
            _isEditMode = false;
            _imageFile = null;
          });
          fetchUserProfile();
        } else {
          _showMessage('Error', data['message'] ?? 'Gagal memperbarui profil.');
        }
      } else {
        _showMessage('Error', 'Kesalahan server: ${response.statusCode}');
      }
    } catch (e) {
      if(!mounted) return;
      Navigator.pop(context);
      _showMessage('Error', 'Kesalahan jaringan: $e');
    }
  }

  Future<void> changePassword() async {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmNewPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ganti Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: oldPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Lama')),
                TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru')),
                TextField(controller: confirmNewPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmNewPasswordController.text) {
                  _showMessage('Error', 'Konfirmasi password baru tidak cocok.');
                  return;
                }
                Navigator.pop(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) { return const AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [ CircularProgressIndicator(), SizedBox(height: 16), Text("Mengganti password...") ])); },
                );
                try {
                  final response = await http.post(Uri.parse('${widget.apiBaseUrl}/change_password.php'), body: {'user_id': widget.userId.toString(), 'old_password': oldPasswordController.text, 'new_password': newPasswordController.text});
                  Navigator.pop(context);
                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    if (data['status'] == 'success') {
                      _showMessage('Berhasil', 'Password berhasil diganti!');
                    } else {
                      _showMessage('Error', data['message'] ?? 'Gagal mengganti password.');
                    }
                  } else {
                    _showMessage('Error', 'Kesalahan server: ${response.statusCode}');
                  }
                } catch (e) {
                  Navigator.pop(context);
                  _showMessage('Error', 'Kesalahan jaringan: $e');
                }
              },
              child: const Text('Ganti'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomePage(apiBaseUrl: widget.apiBaseUrl)), (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: fetchUserProfile,
                child: const Text('Coba Lagi')),
          ],
        ),
      )
          : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return RefreshIndicator(
      onRefresh: fetchUserProfile,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildProfileHeader(),
          _isEditMode ? _buildEditForm() : _buildDisplayInfo(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    ImageProvider<Object> backgroundImage;
    if (_imageFile != null) {
      backgroundImage = FileImage(_imageFile!);
    } else if (_userData?['photo'] != null && _userData!['photo'].isNotEmpty) {
      backgroundImage =
          NetworkImage('${widget.apiBaseUrl}/${_userData!['photo']}');
    } else {
      backgroundImage = const AssetImage("assets/images/logo.png");
    }

    final dynamic rawRating = _userData?['average_rating'];
    double rating = 0.0;
    if (rawRating is num) {
      rating = rawRating.toDouble();
    } else if (rawRating is String) {
      rating = double.tryParse(rawRating) ?? 0.0;
    }

    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(30, 60, 30, 80),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryGreen, darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 68,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.white,
                    backgroundImage: backgroundImage,
                  ),
                ),
                if (_isEditMode)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Material(
                      color: darkGreen,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        onTap: _showImagePickerOptions,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isEditMode
                  ? _usernameController.text
                  : (_userData?['username'] ?? 'Nama Pengguna'),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _userData?['email'] ?? 'email@anda.com',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 12),
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, index) =>
              const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 28.0,
              unratedColor: Colors.amber.withAlpha(80),
              direction: Axis.horizontal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayInfo() {
    return Container(
      transform: Matrix4.translationValues(0.0, -40.0, 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: softShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 5))
                ]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildInfoRow(
                      Icons.location_on_outlined, 'Alamat', _userData?['address']),
                  const Divider(indent: 20, endIndent: 20),
                  _buildInfoRow(
                      Icons.phone_outlined, 'Nomor Telepon', _userData?['no_telp']),
                  const Divider(indent: 20, endIndent: 20),
                  _buildInfoRow(
                      Icons.cake_outlined, 'Usia', _userData?['age']?.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildActionMenu(),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      transform: Matrix4.translationValues(0.0, -40.0, 0.0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: softShadow,
                      blurRadius: 20,
                      offset: const Offset(0, 5))
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Informasi Akun",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGreen)),
                const Divider(height: 28),
                _buildStyledTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline),
                const SizedBox(height: 18),
                _buildStyledTextField(
                    controller: _addressController,
                    label: 'Alamat',
                    icon: Icons.location_on_outlined),
                const SizedBox(height: 18),
                _buildStyledTextField(
                    controller: _phoneNumberController,
                    label: 'Nomor Telepon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 18),
                _buildStyledTextField(
                    controller: _ageController,
                    label: 'Usia',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = false;
                          _imageFile = null;
                          _updateControllers();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: const Text('Batal'))),
              const SizedBox(width: 12),
              Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                      onPressed: updateProfile,
                      icon: const Icon(Icons.save_outlined,color: Colors.white),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          shadowColor: primaryGreen.withOpacity(0.4)))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: softShadow, blurRadius: 15, offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: primaryGreen),
            title: const Text('Edit Profil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _isEditMode = true),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ganti Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: changePassword,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _confirmLogout,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 28),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      subtitle: Text(
        value == null || value.isEmpty ? 'Belum diatur' : value,
        style: const TextStyle(
            fontSize: 17,
            color: Colors.black87,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: cardBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2)),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 380,
          decoration: const BoxDecoration(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}