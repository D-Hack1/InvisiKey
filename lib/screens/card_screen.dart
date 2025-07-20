import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class CardScreen extends StatefulWidget {
  @override
  _CardScreenState createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  String username = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print("🔍 Retrieved token from SharedPreferences: $token");

      if (token == null || token.isEmpty) {
        setState(() {
          username = 'Token missing';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://canara-backend-fjmu.onrender.com/api/user/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("📡 /api/user/me response: ${response.statusCode}");
      print("📨 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['username'] ?? 'Unknown';
        });
      } else {
        setState(() {
          username = 'Failed to load';
        });
      }
    } catch (e) {
      print("❗ Error fetching username: $e");
      setState(() {
        username = 'Error';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Summary',
          style: TextStyle(color: Colors.white), // makes title white
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: IconThemeData(color: Colors.white), // makes back arrow white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Your Balance',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  SizedBox(height: 10),
                  Text('\$513.89',
                      style: TextStyle(
                          fontSize: 32,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("VISA",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  SizedBox(height: 20),
                  Text("**** **** **** 4265",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(username,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      Text("12/22", style: TextStyle(color: Colors.white)),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 30),
            Text("Card Info",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildInfoBox(Icons.flight, "Travel Card", Colors.blue.shade50, Colors.blue),
            _buildInfoBox(Icons.wifi, "Online Payment", Colors.deepPurple.shade50, Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String title, Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 16),
          Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
