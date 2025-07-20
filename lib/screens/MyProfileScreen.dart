import 'package:flutter/material.dart';
import 'package:prototypebank/screens/card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
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
      setState(() {
        username = 'Error';
      });
    }
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ...items.map((item) => Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.settings, size: 20, color: Colors.grey.shade600),
              SizedBox(width: 12),
              Expanded(
                child: Text(item,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade400),
            ],
          ),
        )),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Profile"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueGrey.shade100,
              child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
            ),
            SizedBox(height: 12),
            Text(username,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),

            _buildSection("Account Settings", [
              "Personal & Account Details",
              "Link & Set Primary Account",
              "Manage Payment Channels",
              "Manage Cards"
            ]),

            _buildSection("Security & Privacy", [
              "Touch ID / Face ID",
              "Change PIN",
              "Manage Transaction Rights"
            ]),

            _buildSection("General Settings", [
              "Languages",
              "Services",
              "Cheques"
            ]),
          ],
        ),
      ),
    );
  }
}
