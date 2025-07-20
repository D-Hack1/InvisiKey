import 'package:flutter/material.dart';
import '../widgets/background_scaffold.dart';
import 'rhythm_capture_screen.dart'; // Make sure this path is correct
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _statusMessage = "";

  Future<bool> _checkAvailability(String username, String email) async {
    final url = Uri.parse('https://canara-backend-fjmu.onrender.com/check-availability?username=$username&email=$email');
    try {
      final response = await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['available'] == false) {
          setState(() {
            if (data['field'] == 'username') {
              _statusMessage = "Username is already taken";
            } else if (data['field'] == 'email') {
              _statusMessage = "Email is already registered";
            } else {
              _statusMessage = "Username or email is already taken";
            }
          });
          return false;
        }
        return true;
      } else {
        setState(() => _statusMessage = "Error checking availability. Try again.");
        return false;
      }
    } catch (e) {
      setState(() => _statusMessage = "Network error. Try again.");
      return false;
    }
  }

  void _proceedToRhythmCapture() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _statusMessage = "Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _statusMessage = "Passwords do not match");
      return;
    }

    setState(() => _statusMessage = "Checking availability...");
    final available = await _checkAvailability(username, email);
    if (!available) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RhythmCaptureScreen(
          username: username,
          email: email,
          password: password,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: const Text("Sign Up", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 24)),
                  const SizedBox(height: 20),
                  _buildTextField("Username", _usernameController),
                  _buildTextField("Email", _emailController, keyboardType: TextInputType.emailAddress),
                  _buildTextField("Password", _passwordController, obscureText: true),
                  _buildTextField("Confirm Password", _confirmPasswordController, obscureText: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _proceedToRhythmCapture,
                    child: const Text("Next: Tap Rhythm"),
                  ),
                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_statusMessage, style: const TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
