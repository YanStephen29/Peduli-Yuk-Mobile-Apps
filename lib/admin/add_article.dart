import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';

class AddArticlePage extends StatefulWidget {
  final String apiBaseUrl;
  final int adminId;
  const AddArticlePage({Key? key, required this.apiBaseUrl, required this.adminId}) : super(key: key);

  @override
  _AddArticlePageState createState() => _AddArticlePageState();
}

class _AddArticlePageState extends State<AddArticlePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController sourceLinkController = TextEditingController();
  List<int> selectedCategories = [];
  File? _imageFile;
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_categories.php'));
    if(!mounted) return;
    final jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      setState(() {
        categories = List<Map<String, dynamic>>.from(jsonData['categories']);
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> submitArticle() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, Deskripsi, dan Gambar wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    var request = http.MultipartRequest('POST', Uri.parse('${widget.apiBaseUrl}/add_article.php'));
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['source_link'] = sourceLinkController.text;
    request.fields['categories'] = jsonEncode(selectedCategories);

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    } else {
      request.fields['image_url'] = '';
    }

    try {
      var response = await request.send();
      if(!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Artikel berhasil ditambahkan")));

        Navigator.of(context).pop();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menambahkan artikel")));
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
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
      appBar: AppBar(title: const Text('Tambah Artikel Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(controller: titleController, decoration: _buildInputDecoration('Judul Artikel', Icons.title)),
            const SizedBox(height: 16),
            TextFormField(controller: descriptionController, decoration: _buildInputDecoration('Deskripsi', Icons.description_outlined), maxLines: 5, keyboardType: TextInputType.multiline),
            const SizedBox(height: 16),
            TextFormField(controller: sourceLinkController, decoration: _buildInputDecoration('Link Sumber (Opsional)', Icons.link)),

            _buildSectionTitle('Gambar Sampul'),
            GestureDetector(
              onTap: pickImage,
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(12),
                color: Colors.grey.shade400,
                strokeWidth: 1.5,
                dashPattern: const [6, 6],
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.file(_imageFile!, fit: BoxFit.cover))
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

            _buildSectionTitle('Kategori'),
            if (categories.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: categories.map((category) {
                  int catId = int.parse(category['id'].toString());
                  final isSelected = selectedCategories.contains(catId);
                  return FilterChip(
                    label: Text(category['name']),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedCategories.add(catId);
                        } else {
                          selectedCategories.remove(catId);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : submitArticle,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Simpan Artikel'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}