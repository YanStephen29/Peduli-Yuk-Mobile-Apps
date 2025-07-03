import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:peduliyuk_api/admin/edit_profile_admin.dart';

class ProfileAdminPage extends StatefulWidget {
  final String apiBaseUrl;
  final int adminId;

  const ProfileAdminPage({Key? key, required this.apiBaseUrl, required this.adminId}) : super(key: key);

  @override
  _ProfileAdminPageState createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  Map<String, dynamic> adminData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAdminProfile();
  }

  Future<void> fetchAdminProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/get_admin_profile.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'admin_id': widget.adminId}),
      );
      if(!mounted) return;
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success' && data['admin'] != null) {
        setState(() {
          adminData = data['admin'];

        });
      } else {
        print('Failed to fetch admin profile: ${data['message'] ?? 'Unknown error'}');
        setState(() {

          adminData = {'username': 'Admin Username', 'photo': '', 'no_telp': '', 'id': null};
        });
      }
    } catch (e) {
      print('Exception fetching admin profile: $e');
      setState(() {

        adminData = {'username': 'Admin Username', 'photo': '', 'no_telp': '', 'id': null};
      });
    } finally {
      if(mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    if (adminData['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Admin tidak ditemukan. Tidak bisa mengedit profil.')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileAdminPage(
          apiBaseUrl: widget.apiBaseUrl,
          adminData: adminData,
          adminId: widget.adminId,
        ),
      ),
    );

    if (result == true) {
      fetchAdminProfile();
    }
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildActionMenu(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 54,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: adminData['photo'] != null && adminData['photo'] != ''
                ? NetworkImage('${widget.apiBaseUrl}/${adminData['photo']}') as ImageProvider
                : const AssetImage('assets/images/logo.png'),
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          adminData['username'] ?? 'Admin Username',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (adminData['no_telp'] != null && adminData['no_telp'] != '')
          Text(
            adminData['no_telp'],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
      ],
    );
  }

  Widget _buildActionMenu() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _navigateToEditProfile,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }
}