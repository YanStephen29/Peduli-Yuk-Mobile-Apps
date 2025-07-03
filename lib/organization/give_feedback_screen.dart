import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart' as rating_bar;

class GiveFeedbackScreen extends StatefulWidget {
  final String apiBaseUrl;
  final int donationId;
  final int donationAcceptanceId;
  final int receiverId;
  final VoidCallback onFeedbackSubmitted;

  const GiveFeedbackScreen({
    Key? key,
    required this.apiBaseUrl,
    required this.donationId,
    required this.donationAcceptanceId,
    required this.receiverId,
    required this.onFeedbackSubmitted,
  }) : super(key: key);

  @override
  State<GiveFeedbackScreen> createState() => _GiveFeedbackScreenState();
}

class _GiveFeedbackScreenState extends State<GiveFeedbackScreen> {
  // Palet Warna Konsisten
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color veryLightGreen = Color(0xFFF1F8E9);
  static const Color greyText = Color(0xFF616161);

  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap berikan rating bintang terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/submit_donation_feedback.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'donation_acceptance_id': widget.donationAcceptanceId,
          'donation_id': widget.donationId,
          'receiver_id': widget.receiverId,
          'rating': _rating.toInt(),
          'comment': _commentController.text,
        }),
      );

      final data = json.decode(response.body);

      if (mounted && response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan berhasil dikirim! Terima kasih.'), backgroundColor: darkGreen),
        );
        widget.onFeedbackSubmitted();
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim ulasan: ${data['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengirim ulasan: $e')),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: veryLightGreen,
      appBar: AppBar(
        title: const Text('Beri Ulasan Donasi'),
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.volunteer_activism_outlined,
                    size: 80,
                    color: primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Terima Kasih!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ulasan Anda sangat berarti bagi donatur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: greyText),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryGreen.withOpacity(0.3))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seberapa puaskah Anda?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkGreen),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: rating_bar.RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemSize: 45.0, // Bintang lebih besar
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tulis Komentar (Opsional)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkGreen),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Bagikan pengalaman Anda di sini...',
                      filled: true,
                      fillColor: veryLightGreen.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryGreen, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSending ? null : _submitFeedback,
              child: _isSending
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : const Text(
                'Kirim Ulasan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}