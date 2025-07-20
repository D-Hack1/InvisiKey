import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'button_select_screen.dart';
import 'login_screen.dart'; // Added import for LoginScreen
import 'package:url_launcher/url_launcher.dart';

class RhythmCaptureScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const RhythmCaptureScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<RhythmCaptureScreen> createState() => _RhythmCaptureScreenState();
}

class _RhythmCaptureScreenState extends State<RhythmCaptureScreen> {
  static const int numSamples = 5;
  int currentSample = 1;
  List<List<int>> allSamples = [];
  List<int> _tapTimestamps = [];
  List<int> _tapIntervals = [];
  String _statusMessage = "Tap your rhythm";
  bool _isSubmitting = false;
  bool _showOverlay = false;

  void _handleTap() {
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
    setState(() {
      _tapTimestamps.clear();
      _tapIntervals.clear();
      _statusMessage = "Tap your rhythm";
    });
  }

  void _submitSignupWithButton(String selectedButton) async {
    final samples = allSamples
        .map((intervals) => {"intervals": intervals, "label": "valid_user"})
        .toList();
    print('DEBUG: Sending rhythm_samples: ' + samples.toString());
    try {
      final response = await http.post(
        Uri.parse('https://canara-backend-fjmu.onrender.com/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "email": widget.email,
          "password": widget.password,
          "rhythm_samples": samples,
          "secret_button": selectedButton,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", widget.username);
        await prefs.setString("password", widget.password);
        await prefs.setString("secret_button", selectedButton);
        setState(() {
          _statusMessage = "Signup successful!";
        });
        // Show buffer dialog with green tick for 2 seconds
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.blue.shade500.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
                  SizedBox(height: 20),
                  Text(
                    "Account Created Successfully!",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close dialog if still open
        }
        setState(() {
          _showOverlay = true;
        });
        return;
      } else {
        print("Signup failed with status: "+response.statusCode.toString());
        print("Response body: "+response.body);
        setState(() {
          _statusMessage = "Signup failed. ${response.body}";
          allSamples.clear();
          currentSample = 1;
        });
      }
    } catch (e) {
      print("Error during signup: $e");
      setState(() {
        _statusMessage = "An error occurred. Please try again.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _confirmSample() {
    if (_tapIntervals.length < 2) {
      setState(() {
        _statusMessage = "Please tap at least 3 times before confirming.";
      });
      return;
    }
    setState(() {
      allSamples.add(List.from(_tapIntervals));
      _tapTimestamps.clear();
      _tapIntervals.clear();
      if (currentSample < numSamples) {
        currentSample++;
        _statusMessage = "Sample $currentSample of $numSamples: Tap your rhythm";
      } else {
        // Instead of submitting, go to button select screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ButtonSelectScreen(
              onButtonSelected: (selectedButton) {
                setState(() => _isSubmitting = true);
                _submitSignupWithButton(selectedButton);
              },
            ),
          ),
        );
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Tap Your Rhythm",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _handleTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text("Tap Here"),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Preview: "+getRhythmPreview(),
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _resetRhythm,
                      child: const Text("Reset", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmSample,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(currentSample < numSamples ? "Confirm" : "Confirm & Create Account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/overlay.jpg',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 40),
                        onPressed: () {
                          setState(() {
                            _showOverlay = false;
                          });
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    // Remove previous YouTube button and add two top buttons
                    Positioned(
                      top: 30,
                      left: 0,
                      right: 0,
                      child: Stack(
                        children: [
                          // Left button: Full working demo
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12), // More left shift
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  final url = Uri.parse('https://youtu.be/jW0pKK_oLvs?si=Q6rar86X_03_JTck');
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                },
                                child: const Text(
                                  'Full\nworking\ndemo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.1),
                                ),
                              ),
                            ),
                          ),
                          // Right button: How to Login
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12), // More right shift
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () async {
                                  final url = Uri.parse('https://youtube.com/shorts/-MjnPrmZdQY');
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                },
                                child: const Text(
                                  'How to\nLogin',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.1),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  void _showLoadingAndNavigateWithFade(
      BuildContext context,
      Widget nextScreen, {
        String message = "Please wait...",
        Duration delay = const Duration(seconds: 2),
      }) async {
    final ValueNotifier<bool> isSuccess = ValueNotifier(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: ValueListenableBuilder<bool>(
            valueListenable: isSuccess,
            builder: (_, success, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  success
                      ? const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 60)
                      : const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    success
                        ? "Account Created Successfully!"
                        : message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Wait for initial delay
    await Future.delayed(delay);

    // If this is a signup success flow, show the tick
    if (message.toLowerCase().contains("signing up") ||
        message.toLowerCase().contains("creating your account")) {
      isSuccess.value = true;
      await Future.delayed(const Duration(seconds: 2));
    }

    Navigator.of(context).pop(); // Close dialog

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }


}
