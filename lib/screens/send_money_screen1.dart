import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Added for jsonEncode and jsonDecode
import 'package:http/http.dart' as http; // Added for http requests

import 'rhythm_verify_screen.dart';

class SendMoneyScreen1 extends StatefulWidget {
  @override
  State<SendMoneyScreen1> createState() => _SendMoneyScreen1State();
}

class _SendMoneyScreen1State extends State<SendMoneyScreen1> {
  final nameController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final bankController = TextEditingController();
  final amountController = TextEditingController();
  final pinController = TextEditingController();

  int currentStep = 0;
  bool _transactionSuccess = false;

  int _failedRhythmAttempts = 0;
  bool _isRhythmDeclined = false;
  bool _txnLocked = false;
  int _txnAttemptsLeft = 3;

  List<int> _tapIntervals = []; // Added for rhythm verification intervals

  // Rhythm tap logic
  List<int> _tapTimestamps = [];
  void _handleRhythmTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (_tapTimestamps.isNotEmpty) {
        _tapIntervals.add(now - _tapTimestamps.last);
      }
      _tapTimestamps.add(now);
    });
  }

  void _resetRhythm() {
    setState(() {
      _tapTimestamps.clear();
      _tapIntervals.clear();
    });
  }

  void _goToPinEntry() {
    if (nameController.text.isEmpty ||
        accountController.text.isEmpty ||
        ifscController.text.isEmpty ||
        bankController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
    } else {
      setState(() {
        currentStep = 1;
      });
    }
  }

  void _showRhythmBufferingDialog({required String message, bool isLockout = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.redAccent, size: 48),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Processing payment...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _verifyTransactionPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final response = await http.post(
      Uri.parse('https://canara-backend-fjmu.onrender.com/api/transaction/verify-pin'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"pin": pin}),
    );
    final data = jsonDecode(response.body);
    _txnLocked = data['locked'] == true;
    _txnAttemptsLeft = data['attempts_left'] ?? 0;
    if (_txnLocked) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      _showRhythmBufferingDialog(
        message: data['message'] ?? 'Transaction locked.',
        isLockout: true,
      );
      return false;
    }
    if (!data['success']) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      _showRhythmBufferingDialog(
        message: data['message'] ?? 'Incorrect PIN.',
        isLockout: false,
      );
      return false;
    }
    return true;
  }

  Future<bool> _verifyTransactionRhythm(List<int> intervals, String button) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;
    final response = await http.post(
      Uri.parse('https://canara-backend-fjmu.onrender.com/api/transaction/verify-rhythm'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "tap_rhythm_attempt": intervals,
        "button": button,
      }),
    );
    final data = jsonDecode(response.body);
    _txnLocked = data['locked'] == true;
    _txnAttemptsLeft = data['attempts_left'] ?? 0;
    if (_txnLocked) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      _showRhythmBufferingDialog(
        message: data['message'] ?? 'Transaction locked.',
        isLockout: true,
      );
      return false;
    }
    if (!data['success']) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      _showRhythmBufferingDialog(
        message: data['message'] ?? 'Wrong rhythm.',
        isLockout: false,
      );
      return false;
    }
    return true;
  }

  void _validatePin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final secretButton = prefs.getString('secret_button');
    final savedPassword = prefs.getString('password');

    if (username == null || savedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      return;
    }

    // Transaction PIN verification with backend lockout
    _showProcessingDialog();
    bool pinVerified = await _verifyTransactionPin(pinController.text);
    if (!pinVerified) {
      return;
    }

    // Inline rhythm verification (no extra screen)
    if (_txnLocked) {
      return;
    }
    bool rhythmVerified = false;
    if (_tapIntervals.isEmpty) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      _showRhythmBufferingDialog(
        message: 'Please tap your rhythm before verifying.',
        isLockout: false,
      );
      return;
    }
    rhythmVerified = await _verifyTransactionRhythm(_tapIntervals, secretButton ?? '');
    if (rhythmVerified) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss processing
      if (!mounted) return;
      setState(() {
        _transactionSuccess = true;
        // Reset state after success
        _tapTimestamps.clear();
        _tapIntervals.clear();
        _txnLocked = false;
        _txnAttemptsLeft = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(100, 27, 60, 160),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.25,
            child: Center(
              child: SvgPicture.asset(
                'assets/Canara_Bank_Logo.svg',
                height: screenHeight * 0.08,
                width: screenHeight * 0.01,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.25,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color.fromARGB(0, 155, 200, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_transactionSuccess) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(height: 40),
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          SizedBox(height: 20),
          Text(
            "Transaction Successful!",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    switch (currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("                 Send Money",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _buildTextField("Beneficiary Name", nameController),
            _buildTextField("Account Number", accountController, keyboardType: TextInputType.number),
            _buildTextField("IFSC Code", ifscController),
            _buildTextField("Bank Name", bankController),
            _buildTextField("Amount", amountController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _goToPinEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromARGB(255, 23, 53, 160),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Next"),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Enter PIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _buildTextField("PIN", pinController, obscureText: true, keyboardType: TextInputType.text),
            const SizedBox(height: 40),
            if (currentStep == 1 && !_transactionSuccess) ...[
              // Rhythm tap box with new dark blue color
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _handleRhythmTap,
                  child: Container(
                    width: 120,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3054), // New dark blue color
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (_tapTimestamps.isNotEmpty)
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Small white reset box with NO text
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _resetRhythm,
                  child: Container(
                    width: 60,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white24,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Green verify box, only enabled if rhythm tapped
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (_txnLocked || _tapTimestamps.isEmpty) ? null : _validatePin,
                  child: Container(
                    width: 180,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (_txnLocked || _tapTimestamps.isEmpty) ? Colors.green.shade200 : Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Verify & Continue',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.lightBlue.withOpacity(0.2),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
