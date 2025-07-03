import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';

class AddSuaraKebutuhanScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int userId;
  const AddSuaraKebutuhanScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.userId,
  }) : super(key: key);
  @override
  State<AddSuaraKebutuhanScreen> createState() => _AddSuaraKebutuhanScreenState();
}

class _AddSuaraKebutuhanScreenState extends State<AddSuaraKebutuhanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  DateTime? _selectedDeadline;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _deadlineController.text = '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _deadlineController.text = DateFormat('dd MMMM yyyy, HH:mm').format(_selectedDeadline!);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.apiBaseUrl}/add_suara_kebutuhan.php'),
      );
      request.fields['user_id'] = widget.userId.toString();
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      if (_selectedDeadline != null) {
        request.fields['deadline'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDeadline!);
      } else {
        request.fields['deadline'] = '';
      }

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          filename: _imageFile!.path.split('/').last,
        ));
      }
      var response = await request.send();
      if (!mounted) return;
      var responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suara Kebutuhan berhasil ditambahkan!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan: ${data['message'] ?? 'Unknown error'}.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error jaringan: $e')),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade700, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade700, width: 2)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Suara Kebutuhan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: _buildInputDecoration('Judul Kebutuhan', Icons.title_outlined),
              validator: (value) => value == null || value.isEmpty ? 'Judul tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _buildInputDecoration('Deskripsi Lengkap', Icons.description_outlined),
              maxLines: 5,
              validator: (value) => value == null || value.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              onTap: () => _selectDeadline(context),
              decoration: _buildInputDecoration('Batas Waktu (Opsional)', Icons.calendar_today_outlined),
            ),

            _buildSectionTitle('Gambar Sampul'),
            _buildImagePicker(),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: _buildSubmitButton(),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context),
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: Colors.grey.shade400,
        strokeWidth: 1.5,
        dashPattern: const [6, 6],
        child: Container(
          height: 180,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _imageFile == null ? Colors.grey.shade100 : Colors.transparent,
          ),
          child: _imageFile != null
              ? Image.file(_imageFile!, fit: BoxFit.cover)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 40),
              const SizedBox(height: 8),
              Text('Pilih Gambar (Opsional)', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitForm,
            icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.send_outlined,color: Colors.white),
            label: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kirim Suara Kebutuhan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
