import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RhythmVerifyScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final String button;
  const RhythmVerifyScreen({super.key, this.onSuccess, required this.button});

  @override
  State<RhythmVerifyScreen> createState() => _RhythmVerifyScreenState();
}

class _RhythmVerifyScreenState extends State<RhythmVerifyScreen> {
  List<int> _tapTimestamps = [];
  List<int> _tapIntervals = [];
  bool _isVerifying = false;
  String _statusMessage = "Tap your rhythm to verify";
  int _failedAttempts = 0;
  bool _isDeclined = false;
  bool _isSuccess = false;

  void _handleTap() {
    if (_isDeclined || _isSuccess) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      if (_tapTimestamps.isNotEmpty) {
        _tapIntervals.add(now - _tapTimestamps.last);
      }
      _tapTimestamps.add(now);
    });
  }

  String getRhythmPreview() {
    if (_tapIntervals.isEmpty) return "No rhythm yet";
    return _tapIntervals.map((ms) => ms > 300 ? 'Pause' : 'Tap').join(' - ');
  }

  void _resetRhythm() {
    if (_isDeclined || _isSuccess) return;
    setState(() {
      _tapTimestamps.clear();
      _tapIntervals.clear();
      _statusMessage = "Tap your rhythm to verify";
    });
  }

  void _handleFailedAttempt(String message) {
    _failedAttempts += 1;
    if (_failedAttempts >= 3) {
      setState(() {
        _isDeclined = true;
        _statusMessage = "❌ Transaction Failed: Rhythm Verification Declined";
      });
    } else {
      setState(() {
        _statusMessage = "$message ($_failedAttempts/3)";
      });
    }
  }

  Future<void> _submitVerification() async {
    setState(() {
      _isVerifying = true;
      _statusMessage = "Verifying...";
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final username = prefs.getString('username');
    print('DEBUG: token = ' + (token ?? 'null'));
    print('DEBUG: username = ' + (username ?? 'null'));
    print('DEBUG: Attempting rhythm: ' + _tapIntervals.toString());

    if (token == null) {
      setState(() {
        _statusMessage = "Auth token missing.";
        _isVerifying = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://canara-backend-fjmu.onrender.com/verify-tap'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "tap_rhythm_attempt": _tapIntervals,
          "button": widget.button,
        }),
      );

      setState(() {
        _isVerifying = false;
      });

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["match"] == true) {
          setState(() {
            _isSuccess = true;
            _statusMessage = "✅ Transaction Successful: Your Rhythm Matched";
            _failedAttempts = 0;
          });
          await Future.delayed(const Duration(seconds: 2));
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          _handleFailedAttempt("Rhythm did not match. Try again.");
        }
      } else if (response.statusCode == 401) {
        _handleFailedAttempt("Unauthorized. Try again or fallback.");
      } else {
        final error = jsonDecode(response.body);
        _handleFailedAttempt(
            "Server Error: ${error['detail'] ?? response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _statusMessage = "Network Error: $e";
      });
    }
  }

  Widget _buildFallbackButton() {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, false),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
      child: const Text("Fallback Option"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(100, 27, 60, 160),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Verify Rhythm",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _isSuccess
                          ? Colors.greenAccent
                          : _isDeclined
                          ? Colors.redAccent
                          : Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isDeclined || _isSuccess ? null : _handleTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text("Tap Here"),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isDeclined || _isSuccess ? null : _resetRhythm,
                    child: const Text("Reset",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isVerifying || _isDeclined || _isSuccess
                        ? null
                        : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                    ),
                    child: _isVerifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify & Continue",
                    style: TextStyle(color:Colors.white70),),
                  ),
                  const SizedBox(height: 20),
                  if (_isDeclined) _buildFallbackButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
