import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsPage extends StatelessWidget {
  final String apiBaseUrl;

  const NotificationsPage({Key? key, required this.apiBaseUrl}) : super(key: key);

  Future<List<dynamic>> fetchNotifications() async {
    final response = await http.get(Uri.parse('${apiBaseUrl}/get_notifications.php'));
    final jsonData = json.decode(response.body);
    return jsonData['notifications'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifikasi')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notifications[index]['message']),
                );
              },
            );
          }
        },
      ),
    );
  }
}