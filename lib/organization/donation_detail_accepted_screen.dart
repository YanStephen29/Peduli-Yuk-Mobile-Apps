import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_rating_bar/flutter_rating_bar.dart' as rating_bar;
import 'package:peduliyuk_api/organization/give_feedback_screen.dart';
import 'package:shimmer/shimmer.dart';

class DonationDetailAcceptedScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int donationAcceptanceId;
  final int receiverId;
  final VoidCallback onRefreshParent;

  const DonationDetailAcceptedScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.donationAcceptanceId,
    required this.receiverId,
    required this.onRefreshParent,
  }) : super(key: key);

  @override
  State<DonationDetailAcceptedScreen> createState() =>
      _DonationDetailAcceptedScreenState();
}

class _DonationDetailAcceptedScreenState
    extends State<DonationDetailAcceptedScreen> {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color greyText = Color(0xFF616161);

  Map<String, dynamic>? _donationDetails;
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedDeliveryMethod;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _fetchDonationDetails();
  }

  Future<void> _fetchDonationDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(
          '${widget.apiBaseUrl}/get_accepted_donation_details.php?donation_acceptance_id=${widget.donationAcceptanceId}'));
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _donationDetails = data['donation_details'];
            _selectedDeliveryMethod = _donationDetails!['delivery_method'];
            if (_donationDetails!['scheduled_delivery_date'] != null) {
              try {
                _selectedDate = DateTime.tryParse(
                    _donationDetails!['scheduled_delivery_date']);
                if (_selectedDate != null) {
                  _dateController.text =
                      DateFormat('d MMMM yyyy').format(_selectedDate!);
                }
              } catch (e) {
              }
            }
          });
        } else {
          setState(
                  () => _errorMessage = data['message'] ?? 'Gagal memuat detail.');
        }
      } else {
        setState(() => _errorMessage = 'Gagal terhubung ke server.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateScheduling() async {
    if (_selectedDeliveryMethod == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap lengkapi metode dan tanggal pengambilan.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
            '${widget.apiBaseUrl}/update_donation_status_and_schedule.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'donation_acceptance_id': widget.donationAcceptanceId,
          'donation_id': _donationDetails!['donation_id'],
          'delivery_method': _selectedDeliveryMethod,
          'scheduled_delivery_date':
          DateFormat('yyyy-MM-dd').format(_selectedDate!),
        }),
      );
      final data = json.decode(response.body);
      if (mounted && response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Penjadwalan berhasil disimpan!'),
          backgroundColor: darkGreen,
        ));
        await _fetchDonationDetails();
        widget.onRefreshParent();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: ${data['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _pickedImage = File(pickedFile.path));
  }

  Future<void> _confirmReceived() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap unggah foto bukti penerimaan.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      var request = http.MultipartRequest('POST',
          Uri.parse('${widget.apiBaseUrl}/confirm_donation_received.php'));
      request.fields['donation_acceptance_id'] =
          widget.donationAcceptanceId.toString();
      request.fields['donation_id'] = _donationDetails!['donation_id'].toString();
      request.fields['receiver_id'] = widget.receiverId.toString();
      request.fields['received_date'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      request.files
          .add(await http.MultipartFile.fromPath('photo', _pickedImage!.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (mounted && response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Penerimaan berhasil dikonfirmasi!'),
            backgroundColor: darkGreen));
        await _fetchDonationDetails();
        widget.onRefreshParent();
        _showFeedbackPrompt();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: ${data['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedbackPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beri Ulasan?', style: TextStyle(color: darkGreen)),
        content: const Text(
            'Donasi telah selesai. Apakah Anda ingin memberikan ulasan untuk donatur sekarang?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              child: const Text('Nanti', style: TextStyle(color: greyText)),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              }),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Ya, Beri Ulasan'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GiveFeedbackScreen(
                        apiBaseUrl: widget.apiBaseUrl,
                        donationId: int.parse(
                            _donationDetails!['donation_id'].toString()),
                        donationAcceptanceId: widget.donationAcceptanceId,
                        receiverId: widget.receiverId,
                        onFeedbackSubmitted: () {
                          Navigator.of(context).pop(true);
                          widget.onRefreshParent();
                        },
                      )));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final cleanPhoneNumber =
    phoneNumber.startsWith('0') ? '62${phoneNumber.substring(1)}' : phoneNumber;
    final url = Uri.parse("https://wa.me/$cleanPhoneNumber");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryLightGreen,
      appBar: AppBar(
        title: const Text('Detail Penerimaan Donasi'),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _errorMessage != null
          ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
          ))
          : _donationDetails == null
          ? const Center(child: Text('Data tidak ditemukan.'))
          : _buildDetailsView(),
    );
  }

  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDonorInfoSection(),
          const SizedBox(height: 16),
          _buildDonationInfoSection(),
          const SizedBox(height: 16),
          _buildItemDetailsSection(),
          const SizedBox(height: 16),
          _buildMainActionSection(),
        ],
      ),
    );
  }

  Widget _buildStyledCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _buildDonorInfoSection() {
    final donorUsername =
        _donationDetails!['donor_username'] ?? 'Tidak Diketahui';
    final donorPhoto = _donationDetails!['donor_photo'] != null
        ? '${widget.apiBaseUrl}/${_donationDetails!['donor_photo']}'
        : null;
    final donorAddress = _donationDetails!['donor_address'] ?? 'Tidak tersedia';
    final donorPhoneNumber = _donationDetails!['donor_no_telp'];

    return _buildStyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: lightGreen.withOpacity(0.2),
              backgroundImage: donorPhoto != null ? NetworkImage(donorPhoto) : null,
              child: donorPhoto == null
                  ? const Icon(Icons.person, size: 30, color: darkGreen)
                  : null,
            ),
            title: Text(donorUsername,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkGreen)),
            subtitle: const Text('Donatur', style: TextStyle(color: greyText)),
          ),
          const Divider(height: 24),
          _buildDetailRow(
              Icons.location_on_outlined, 'Alamat', donorAddress),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.phone_outlined, 'Telepon',
              donorPhoneNumber ?? 'Tidak tersedia'),
        ],
      ),
    );
  }

  Widget _buildDonationInfoSection() {
    final donationType = _donationDetails!['donation_type'] ?? 'N/A';
    final donationStatus = _donationDetails!['donation_status'] ?? 'N/A';
    final tanggalPengambilan = _donationDetails!['tanggal_pengambilan'] != null
        ? DateFormat('d MMMM yyyy, HH:mm')
        .format(DateTime.parse(_donationDetails!['tanggal_pengambilan']))
        : 'N/A';

    return _buildStyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Donasi',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
          const SizedBox(height: 16),
          _buildDetailRow(
              Icons.category_outlined, 'Tipe Donasi', donationType.toUpperCase()),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.info_outline, 'Status', donationStatus),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.event_available_outlined, 'Waktu Pengambilan',
              tanggalPengambilan),
        ],
      ),
    );
  }

  Widget _buildItemDetailsSection() {
    final items = _donationDetails!['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return _buildStyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Item',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
          const SizedBox(height: 8),
          ...items.map((item) {
            final title = item['item_name'] ?? item['item_type'] ?? 'Item';
            final size = item['size'] ?? '-';
            final defects = item['defects'] ?? 'Tidak ada';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: const Icon(Icons.check_box_outline_blank_rounded,
                  color: lightGreen),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('Ukuran: $size, Kondisi: $defects',
                  style: const TextStyle(color: greyText)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainActionSection() {
    final status = _donationDetails!['donation_status'];
    switch (status) {
      case 'Found Receiver':
        return _buildSchedulingAction();
      case 'On Delivery':
        return _buildConfirmationAction();
      case 'Received':
      case 'Success':
        return _buildFeedbackAction();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSchedulingAction() {
    final donorPhoneNumber = _donationDetails!['donor_no_telp'];
    return _buildStyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atur Jadwal Pengambilan',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
            const SizedBox(height: 16),
            const Text('Metode Pengambilan:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            RadioListTile<String>(
                title: const Text('Ambil Sendiri'),
                value: 'ambil_sendiri',
                groupValue: _selectedDeliveryMethod,
                onChanged: (v) => setState(() => _selectedDeliveryMethod = v),
                activeColor: primaryGreen),
            RadioListTile<String>(
                title: const Text('Jasa Pengiriman'),
                value: 'jasa_pengiriman',
                groupValue: _selectedDeliveryMethod,
                onChanged: (v) => setState(() => _selectedDeliveryMethod = v),
                activeColor: primaryGreen),
            const SizedBox(height: 16),
            const Text('Tanggal Pengambilan:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)));
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _dateController.text = DateFormat('d MMMM yyyy').format(picked);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Pilih Tanggal',
                suffixIcon: const Icon(Icons.calendar_today, color: primaryGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
                child: Text('Hubungi donatur untuk koordinasi:',
                    style: TextStyle(color: greyText))),
            if (donorPhoneNumber != null)
              Center(
                  child: IconButton(
                      icon: Image.asset('assets/whatsapp.png', height: 40, width: 40),
                      onPressed: () => _launchWhatsApp(donorPhoneNumber))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Simpan Jadwal'),
                onPressed: _isLoading ? null : _updateScheduling,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            )
          ],
        ));
  }

  Widget _buildConfirmationAction() {
    return _buildStyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Konfirmasi Penerimaan',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedImage == null
                    ? Container(
                    width: 200,
                    height: 200,
                    color: veryLightGreen,
                    child: const Icon(Icons.image_outlined,
                        size: 50, color: greyText))
                    : Image.file(_pickedImage!,
                    width: 200, height: 200, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Unggah Foto Bukti'),
              onPressed: _isLoading ? null : _pickImage,
              style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Telah Diterima'),
              onPressed: _pickedImage == null || _isLoading ? null : _confirmReceived,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ));
  }

  Widget _buildFeedbackAction() {
    final receivedAt = _donationDetails!['received_at'] != null
        ? DateFormat('d MMMM yyyy, HH:mm')
        .format(DateTime.parse(_donationDetails!['received_at']))
        : 'N/A';
    final receivedPhotoUrl = _donationDetails!['received_photo_url'] != null
        ? '${widget.apiBaseUrl}/${_donationDetails!['received_photo_url']}'
        : null;
    final rating = _donationDetails!['rating'];
    final feedbackComment = _donationDetails!['feedback_comment'];

    return _buildStyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Donasi Selesai',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: darkGreen)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.check_circle, 'Diterima Pada', receivedAt),
            if (receivedPhotoUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Foto Bukti:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Center(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(receivedPhotoUrl,
                          height: 200, fit: BoxFit.cover))),
            ],
            const Divider(height: 32),
            if (rating != null) ...[
              const Text('Ulasan Anda:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(children: [
                rating_bar.RatingBarIndicator(
                  rating: double.tryParse(rating.toString()) ?? 0.0,
                  itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 24.0,
                ),
                const SizedBox(width: 8),
                Text('($rating)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.amber)),
              ]),
              if (feedbackComment != null && feedbackComment != '') ...[
                const SizedBox(height: 8),
                Text('"$feedbackComment"',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: greyText)),
              ]
            ] else ...[
              const Center(
                  child: Text('Anda belum memberikan ulasan.',
                      style: TextStyle(color: greyText))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('Beri Ulasan Sekarang'),
                  onPressed: _showFeedbackPrompt,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              )
            ]
          ],
        ));
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: primaryGreen, size: 20),
      const SizedBox(width: 16),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: greyText)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ])),
    ]);
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              height: 120),
          const SizedBox(height: 16),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              height: 150),
          const SizedBox(height: 16),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              height: 200),
          const SizedBox(height: 16),
          Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              height: 300),
        ]),
      ),
    );
  }
}