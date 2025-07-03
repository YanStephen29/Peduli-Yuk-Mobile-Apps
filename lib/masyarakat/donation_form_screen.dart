import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';


enum ClothingType {
  kaos,
  kemeja,
  celana,
  pakaianDalam,
  lainnya,
}

class DonationFormScreen extends StatefulWidget {
  final String donationType;
  final int userId;
  const DonationFormScreen({super.key, required this.donationType, required this.userId});
  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final String _baseUrl = 'http://192.168.64.247/peduliyuk_api';
  int? _currentDonationId;
  bool _isLoading = false;
  bool _isStartingDonation = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  ClothingType? _selectedClothingType;
  final TextEditingController _clothingSizeController = TextEditingController();
  final TextEditingController _clothingDefectsController = TextEditingController();
  File? _clothingFrontPhoto;
  File? _clothingBackPhoto;

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemSizeController = TextEditingController();
  final TextEditingController _itemDefectsController = TextEditingController();
  File? _itemFrontPhoto;
  File? _itemBackPhoto;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _startNewDonation();
  }

  @override
  void dispose() {
    _clothingSizeController.dispose();
    _clothingDefectsController.dispose();
    _itemNameController.dispose();
    _itemSizeController.dispose();
    _itemDefectsController.dispose();
    super.dispose();
  }

  void _showMessage(String title, String message, {bool isError = false}) {
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

  Future<void> _startNewDonation() async {
    setState(() => _isStartingDonation = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/upload_donation.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'donation_type': widget.donationType,
          'id_user': widget.userId,
        }),
      );
      if (!mounted) return;
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        setState(() => _currentDonationId = responseData['donation_id']);
      } else {
        _showMessage('Error', responseData['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error', 'Terjadi kesalahan jaringan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isStartingDonation = false);
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      _showMessage('Error', 'Gagal memilih gambar: $e', isError: true);
    }
    return null;
  }

  Future<String?> _uploadImage(File imageFile) async {
    if (!mounted) return null;
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload_image.php'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        return responseData['image_url'];
      } else {
        _showMessage('Error Upload Gambar', responseData['message'], isError: true);
        return null;
      }
    } catch (e) {
      _showMessage('Error Upload Gambar', 'Terjadi kesalahan jaringan: $e', isError: true);
      return null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem(bool isFinish) async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentDonationId == null) {
      _showMessage('Error', 'Harap tunggu hingga ID donasi dibuat.');
      return;
    }

    setState(() => _isLoading = true);

    String? frontPhotoUrl, backPhotoUrl;
    try {
      if (widget.donationType == 'pakaian') {
        if (_clothingFrontPhoto != null) frontPhotoUrl = await _uploadImage(_clothingFrontPhoto!);
        if (_clothingBackPhoto != null) backPhotoUrl = await _uploadImage(_clothingBackPhoto!);
      } else {
        if (_itemFrontPhoto != null) frontPhotoUrl = await _uploadImage(_itemFrontPhoto!);
        if (_itemBackPhoto != null) backPhotoUrl = await _uploadImage(_itemBackPhoto!);
      }

      final Map<String, dynamic> itemData;
      String apiEndpoint;
      if (widget.donationType == 'pakaian') {
        String clothingTypeValue;
        switch (_selectedClothingType!) {
          case ClothingType.pakaianDalam:
            clothingTypeValue = 'pakaian_dalam';
            break;
          default:
            clothingTypeValue = _selectedClothingType!.name;
            break;
        }
        itemData = {
          'donation_id': _currentDonationId,
          'clothing_type': clothingTypeValue,
          'size': _clothingSizeController.text,
          'defects': _clothingDefectsController.text,
          'front_photo_url': frontPhotoUrl ?? '',
          'back_photo_url': backPhotoUrl ?? ''
        };
        apiEndpoint = 'upload_clothing_item.php';
      } else {
        itemData = {
          'donation_id': _currentDonationId,
          'item_name': _itemNameController.text,
          'size': _itemSizeController.text,
          'defects': _itemDefectsController.text,
          'front_photo_url': frontPhotoUrl ?? '',
          'back_photo_url': backPhotoUrl ?? ''
        };
        apiEndpoint = 'upload_general_item.php';
      }

      final response = await http.post(Uri.parse('$_baseUrl/$apiEndpoint'), headers: {'Content-Type': 'application/json'}, body: json.encode(itemData));
      if (!mounted) return;
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Item berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );

        if (isFinish) {
          Navigator.of(context).pop(true);
        } else {
          _clearForm();
        }
      } else {
        _showMessage('Error', responseData['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error', 'Terjadi kesalahan saat menambahkan item: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    if (widget.donationType == 'pakaian') {
      setState(() {
        _selectedClothingType = null;
        _clothingSizeController.clear();
        _clothingDefectsController.clear();
        _clothingFrontPhoto = null;
        _clothingBackPhoto = null;
      });
    } else {
      setState(() {
        _itemNameController.clear();
        _itemSizeController.clear();
        _itemDefectsController.clear();
        _itemFrontPhoto = null;
        _itemBackPhoto = null;
      });
    }
  }


  InputDecoration _buildInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade700, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade700, width: 2)),
    );
  }

  Widget _buildImagePickerCard(String title, File? imageFile, Function(File?) onImagePicked) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageSourceDialog(onImagePicked),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: Colors.grey.shade400,
                strokeWidth: 1.5,
                dashPattern: const [6, 6],
                child: Container(
                  height: 160,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: imageFile == null ? Colors.grey.shade100 : Colors.transparent,
                  ),
                  child: imageFile != null
                      ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(imageFile, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => onImagePicked(null),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade600, size: 40),
                      const SizedBox(height: 8),
                      Text('Pilih Gambar', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showImageSourceDialog(Function(File?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Pilih Sumber Gambar', style: Theme.of(context).textTheme.titleLarge),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  final file = await _pickImage(ImageSource.gallery);
                  onImagePicked(file);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () async {
                  final file = await _pickImage(ImageSource.camera);
                  onImagePicked(file);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPakaian = widget.donationType == 'pakaian';
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Donasi ${isPakaian ? 'Pakaian' : 'Barang'}'),
      ),
      body: _isStartingDonation
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            if (isPakaian) ..._buildPakaianForm() else ..._buildBarangForm(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isPakaian = widget.donationType == 'pakaian';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2))
      ),
      child: Row(
        children: [
          Icon(
            isPakaian ? Icons.checkroom_outlined : Icons.widgets_outlined,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rincian Item Donasi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID Donasi: ${_currentDonationId ?? "Memulai..."}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPakaianForm() {
    return [
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detail Pakaian", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              DropdownButtonFormField<ClothingType>(
                value: _selectedClothingType,
                decoration: _buildInputDecoration('Jenis Pakaian'),
                hint: const Text('Pilih jenis pakaian'),
                items: ClothingType.values.map((type) {
                  return DropdownMenuItem<ClothingType>(
                    value: type,
                    child: Text(type.name.replaceFirst('pakaianDalam', 'Pakaian Dalam')),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedClothingType = newValue),
                validator: (value) => value == null ? 'Jenis pakaian harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _clothingSizeController, decoration: _buildInputDecoration('Ukuran (Contoh: M, L, 42)')),
              const SizedBox(height: 16),
              TextFormField(controller: _clothingDefectsController, decoration: _buildInputDecoration('Kekurangan (Opsional)'), maxLines: 3),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _buildImagePickerCard('Foto Tampak Depan', _clothingFrontPhoto, (file) => setState(() => _clothingFrontPhoto = file)),
      const SizedBox(height: 16),
      _buildImagePickerCard('Foto Tampak Belakang (Opsional)', _clothingBackPhoto, (file) => setState(() => _clothingBackPhoto = file)),
    ];
  }

  List<Widget> _buildBarangForm() {
    return [
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Detail Barang", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              TextFormField(
                controller: _itemNameController,
                decoration: _buildInputDecoration('Nama Barang'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Nama barang tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _itemSizeController, decoration: _buildInputDecoration('Ukuran (Contoh: Kecil, 20x30cm)')),
              const SizedBox(height: 16),
              TextFormField(controller: _itemDefectsController, decoration: _buildInputDecoration('Kekurangan (Opsional)'), maxLines: 3),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      _buildImagePickerCard('Foto Tampak Depan', _itemFrontPhoto, (file) => setState(() => _itemFrontPhoto = file)),
      const SizedBox(height: 16),
      _buildImagePickerCard('Foto Tampak Belakang (Opsional)', _itemBackPhoto, (file) => setState(() => _itemBackPhoto = file)),
    ];
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(top: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _addItem(false),
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.add_circle_outline),
                label: const Text('Tambah Lagi'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _addItem(true),
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Selesai & Kirim'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
