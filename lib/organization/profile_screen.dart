import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'dart:ui'; // Diperlukan untuk ImageFilter

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}


class ProfileScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color cardBackgroundColor = Color(0xFFF8F9FA);
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color greyText = Color(0xFF616161);
  static const Color softShadow = Color(0x222E7D32);

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  final _usernameController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _addressController = TextEditingController();

  File? _pickedImage;
  String? _currentPhotoUrl;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _noTelpController.dispose();
    _organizationNameController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.get(Uri.parse(
          '${widget.apiBaseUrl}/get_user_profile_organization.php?user_id=${widget.userId}'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _profileData = data['data'];
            _usernameController.text = _profileData!['username'] ?? '';
            _noTelpController.text = _profileData!['no_telp'] ?? '';
            _addressController.text = _profileData!['address'] ?? '';
            _currentPhotoUrl = _profileData!['photo'];

            final role = _profileData!['role']?.toString().toLowerCase() ?? '';
            if (role == 'umkm' || role == 'lembaga_sosial') {
              _organizationNameController.text = _profileData!['organization_name'] ?? '';
            }
          });
        } else {
          setState(() => _errorMessage = data['message'] ?? 'Gagal memuat profil.');
        }
      } else {
        setState(() => _errorMessage = 'Gagal terhubung ke server.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan jaringan: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${widget.apiBaseUrl}/update_user_profile_organization.php'));
      request.fields['user_id'] = widget.userId.toString();
      request.fields['username'] = _usernameController.text;
      request.fields['no_telp'] = _noTelpController.text;
      request.fields['role'] = _profileData!['role'];

      final role = _profileData!['role']?.toString().toLowerCase() ?? '';
      if (role == 'umkm' || role == 'lembaga_sosial') {
        request.fields['organization_name'] = _organizationNameController.text;
        request.fields['address'] = _addressController.text;
      } else if (role == 'masyarakat') {
        request.fields['address'] = _addressController.text;
      }

      if (_pickedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', _pickedImage!.path));
      } else if (_currentPhotoUrl != null) {
        request.fields['current_photo'] = _currentPhotoUrl!;
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (mounted && response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: darkGreen));
        _fetchProfileData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${data['message'] ?? 'Error'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmNewPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password baru tidak cocok.')));
      return;
    }
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field password harus diisi.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/change_password_organization.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      );
      final data = json.decode(response.body);
      if (mounted && response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: darkGreen));
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${data['message'] ?? 'Error'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ganti Password', style: TextStyle(color: darkGreen)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(controller: _currentPasswordController, label: 'Password Lama', isObscure: true, icon: Icons.password),
              const SizedBox(height: 16),
              _buildStyledTextField(controller: _newPasswordController, label: 'Password Baru', isObscure: true, icon: Icons.lock_outline),
              const SizedBox(height: 16),
              _buildStyledTextField(controller: _confirmNewPasswordController, label: 'Konfirmasi Password Baru', isObscure: true, icon: Icons.lock_outline),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _currentPasswordController.clear();_newPasswordController.clear();_confirmNewPasswordController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Batal', style: TextStyle(color: greyText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: _changePassword,
              child: const Text('Ganti'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Logout', style: TextStyle(color: darkGreen)),
          content: const Text('Anda yakin ingin keluar dari aplikasi?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal', style: TextStyle(color: greyText))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onLogout();
              },
              child: const Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // [UI-UPDATE] Latar belakang utama PUTIH
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
          : _profileData == null
          ? const Center(child: Text('Data profil tidak ditemukan.'))
          : _buildProfileLayout(),
    );
  }

  Widget _buildProfileLayout() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildProfileHeader(),
        _buildInfoContainer(),
        _buildActions(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
        ? '${widget.apiBaseUrl}/$_currentPhotoUrl'
        : null;

    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(30, 60, 30, 80), // Padding disesuaikan dengan bentuk
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
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : (photoUrl != null ? NetworkImage(photoUrl) : null),
                    child: (_pickedImage == null && photoUrl == null)
                        ? const Icon(Icons.person, size: 60, color: primaryGreen)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Material(
                    color: darkGreen,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _pickImage,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _profileData!['username'] ?? 'Nama Pengguna',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _profileData!['email'] ?? 'email@pengguna.com',
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContainer() {
    final userRole = _profileData!['role']?.toString().toLowerCase() ?? '';
    final positionName = _profileData!['position_name'] ?? 'Tidak ada posisi';

    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      transform: Matrix4.translationValues(0.0, -40.0, 0.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: softShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkGreen),
          ),
          const Divider(height: 28, thickness: 0.8),
          _buildStyledTextField(controller: _usernameController, label: 'Username', icon: Icons.person_outline),
          const SizedBox(height: 18),
          _buildStyledTextField(controller: _noTelpController, label: 'Nomor Telepon', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 18),
          if (userRole == 'umkm' || userRole == 'lembaga_sosial') ...[
            _buildStyledTextField(controller: _organizationNameController, label: 'Nama Organisasi/Usaha', icon: Icons.business_center_outlined),
            const SizedBox(height: 18),
          ],
          _buildStyledTextField(controller: _addressController, label: 'Alamat', icon: Icons.location_on_outlined, maxLines: 3),
          const SizedBox(height: 18),
          _buildInfoDisplay('Role', _profileData!['role'] ?? 'Pengguna', Icons.verified_user_outlined),
          if (userRole == 'umkm' || userRole == 'lembaga_sosial') ...[
            const SizedBox(height: 16),
            _buildInfoDisplay('Posisi', positionName, Icons.badge_outlined),
          ]
        ],
      ),
    );
  }

  Widget _buildActions(){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      transform: Matrix4.translationValues(0.0, -30.0, 0.0), // Efek tumpuk minor
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
            label: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('Simpan Perubahan'),
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              elevation: 5,
              shadowColor: softShadow,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showChangePasswordDialog,
            child: const Text('Ganti Password'),
            style: OutlinedButton.styleFrom(
              foregroundColor: darkGreen,
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 40, indent: 20, endIndent: 20),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w500)),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDisplay(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(" $label", style: const TextStyle(color: greyText, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor)
          ),
          child: Row(
            children: [
              Icon(icon, color: primaryGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: darkGreen, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    bool isEnabled = true,
    bool isObscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: controller != null ? null : initialValue,
      enabled: isEnabled,
      obscureText: isObscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: cardBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderColor)),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: 330,
          decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80)
              )
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}