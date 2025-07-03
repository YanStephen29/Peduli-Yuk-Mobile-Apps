import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:peduliyuk_api/controller/admin_main_screen.dart';

class EditArticlePage extends StatefulWidget {
  final String apiBaseUrl;
  final Map<String, dynamic> article;
  final int adminId;

  const EditArticlePage({Key? key, required this.apiBaseUrl, required this.article, required this.adminId}) : super(key: key);
  @override
  _EditArticlePageState createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController sourceLinkController;
  List<Map<String, dynamic>> categories = [];
  List<int> selectedCategories = [];
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.article['title']);
    descriptionController = TextEditingController(text: widget.article['description']);
    sourceLinkController = TextEditingController(text: widget.article['source_link']);
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('${widget.apiBaseUrl}/get_categories.php'));
    if (!mounted) return;
    final jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      setState(() {
        categories = List<Map<String, dynamic>>.from(jsonData['categories']);
        selectedCategories = List<int>.from(json.decode(widget.article['category_ids']?.toString() ?? '[]'));
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

  Future<void> updateArticle() async {
    setState(() => _isLoading = true);
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${widget.apiBaseUrl}/edit_article.php'),
    );
    request.fields['id'] = widget.article['id'].toString();
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['source_link'] = sourceLinkController.text;
    request.fields['categories'] = jsonEncode(selectedCategories);
    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    }

    try {
      var response = await request.send();
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Artikel berhasil diperbarui")));
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMainScreen(
                apiBaseUrl: widget.apiBaseUrl,
                adminId: widget.adminId,
              ),
            ),
                (route) => route.isFirst,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memperbarui artikel")));
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text('Edit Artikel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(controller: titleController, decoration: _buildInputDecoration('Judul Artikel', Icons.title)),
            const SizedBox(height: 16),
            TextFormField(controller: descriptionController, decoration: _buildInputDecoration('Deskripsi', Icons.description_outlined), maxLines: 5),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_imageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_imageFile!, width: double.infinity, fit: BoxFit.cover),
                        )
                      else if (widget.article['image_url'] != null && widget.article['image_url'] != '')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network('${widget.apiBaseUrl}/${widget.article['image_url']}', width: double.infinity, fit: BoxFit.cover),
                        ),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.8), size: 40),
                          const SizedBox(height: 8),
                          Text('Ubah Gambar', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                        ],
                      ),
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
                onPressed: _isLoading ? null : updateArticle,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Update Artikel'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}