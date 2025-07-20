import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'rhythm_verify_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool _obscureText = true;

  ValueNotifier<String?> _loginErrorNotifier = ValueNotifier(null);

  // State for integrated login flow
  bool _credentialsVerified = false;
  bool _isVerifying = false;
  bool _isDeclined = false;
  int _failedAttempts = 0;
  String? _userSecretButton; // Store the user's secret button from backend
  final List<String> _buttonNames = [
    'Contact Us', 'Feedback', 'Help', 'About', 'Support'
  ];
  List<int> _tapTimestamps = [];
  List<int> _tapIntervals = [];
  String _statusMessage = "Tap your rhythm on your secret button";
  String? _authToken;

  void _handleTap(String buttonName) {
    if (_isDeclined || !_credentialsVerified) return;
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
      _statusMessage = "Tap your rhythm on your secret button";
    });
  }

  // Buffering modal for rhythm attempts and lockout
  void _showRhythmBufferingDialog({required String message, bool isLockout = false}) {
    showDialog(
      context: context,
      barrierDismissible: true, // Always allow close
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red cross icon
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

  void _verifyAndContinue() async {
    if (_userSecretButton == null) {
      setState(() {
        _statusMessage = "Error: Secret button not found. Please try logging in again.";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = "Verifying...";
    });
    try {
      final response = await http.post(
        Uri.parse('https://canara-backend-fjmu.onrender.com/verify-tap'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_authToken"
        },
        body: jsonEncode({
          "tap_rhythm_attempt": _tapIntervals,
          "button": _userSecretButton,
        }),
      );
      setState(() {
        _isVerifying = false;
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["match"] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainNavigationScreen()),
          );
        } else {
          setState(() {
            _failedAttempts += 1;
            if (_failedAttempts >= 3) {
              _isDeclined = true;
              _statusMessage = "❌ Login Failed: Rhythm Verification Declined";
              _showRhythmBufferingDialog(
                message: "Account locked due to too many failed rhythm attempts. Please try again after 5 minutes or contact support.",
                isLockout: true,
              );
            } else {
              _showRhythmBufferingDialog(
                message: "Wrong rhythm. ${3 - _failedAttempts} attempts left.",
                isLockout: false,
              );
            }
            _tapTimestamps.clear();
            _tapIntervals.clear();
          });
        }
      } else if (response.statusCode == 423) {
        // Account locked
        final data = jsonDecode(response.body);
        setState(() {
          _isDeclined = true;
          _statusMessage = "❌ Account Locked: ${data['detail'] ?? 'Your account has been locked due to multiple failed rhythm attempts.'}";
          _showRhythmBufferingDialog(
            message: "Account locked due to too many failed rhythm attempts. Please try again after 5 minutes or contact support.",
            isLockout: true,
          );
        });
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        // Failed rhythm verification with remaining attempts
        final data = jsonDecode(response.body);
        setState(() {
          _failedAttempts += 1;
          if (_failedAttempts >= 3) {
            _isDeclined = true;
            _statusMessage = "❌ Account Locked: ${data['detail'] ?? 'Account locked due to multiple failed attempts'}";
            _showRhythmBufferingDialog(
              message: "Account locked due to too many failed rhythm attempts. Please try again after 5 minutes or contact support.",
              isLockout: true,
            );
          } else {
            _showRhythmBufferingDialog(
              message: "Wrong rhythm. ${3 - _failedAttempts} attempts left.",
              isLockout: false,
            );
            _statusMessage = data['detail'] ?? "Rhythm verification failed. Try again. ($_failedAttempts/3)";
          }
          _tapTimestamps.clear();
          _tapIntervals.clear();
        });
      } else {
        setState(() {
          _failedAttempts += 1;
          if (_failedAttempts >= 3) {
            _isDeclined = true;
            _statusMessage = "❌ Login Failed: Rhythm Verification Declined";
            _showRhythmBufferingDialog(
              message: "Account locked due to too many failed rhythm attempts. Please try again after 5 minutes or contact support.",
              isLockout: true,
            );
          } else {
            _showRhythmBufferingDialog(
              message: "Wrong rhythm. ${3 - _failedAttempts} attempts left.",
              isLockout: false,
            );
            _statusMessage = "Verification failed. Try again. ($_failedAttempts/3)";
          }
          _tapTimestamps.clear();
          _tapIntervals.clear();
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _statusMessage = "Network Error: $e";
      });
    }
  }

  void _login() async {
    String username = userController.text.trim();
    String password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog("Please enter both username and password");
      return;
    }

    _loginErrorNotifier.value = null; // reset
    _showLoadingDialog();

    try {
      final response = await http.post(
        Uri.parse("https://canara-backend-fjmu.onrender.com/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data.containsKey("access_token")) {
        Navigator.pop(context); // close dialog
        final token = data["access_token"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("username", username);
        await prefs.setString("password", password);
        
        // Get user's secret button from backend
        try {
          final userMeResponse = await http.get(
            Uri.parse('https://canara-backend-fjmu.onrender.com/api/user/me'),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
          );
          if (userMeResponse.statusCode == 200) {
            final userMeData = jsonDecode(userMeResponse.body);
            if (userMeData["secret_button"] != null) {
              setState(() {
                _userSecretButton = userMeData["secret_button"];
                _credentialsVerified = true;
                _authToken = token;
              });
            } else {
              setState(() {
                _statusMessage = "Error: Secret button not found. Please contact support.";
                _credentialsVerified = true;
                _authToken = token;
              });
            }
          } else {
            setState(() {
              _statusMessage = "Error: Could not retrieve user data. Please try again.";
              _credentialsVerified = true;
              _authToken = token;
            });
          }
        } catch (e) {
          setState(() {
            _statusMessage = "Error: Could not retrieve user data. Please try again.";
            _credentialsVerified = true;
            _authToken = token;
          });
        }
      } else if (response.statusCode == 423) {
        // Account locked
        _loginErrorNotifier.value = "Account Locked: ${data['detail'] ?? 'Your account has been locked due to multiple failed attempts. Please contact support.'}";
      } else if (response.statusCode == 401) {
        // Invalid credentials with remaining attempts info
        _loginErrorNotifier.value = data['detail'] ?? 'Invalid credentials';
      } else {
        _loginErrorNotifier.value =
        "Login failed: ${data['detail'] ?? 'Invalid credentials'}";
      }
    } catch (e) {
      _loginErrorNotifier.value = e.toString().contains("Connection refused")
          ? "Backend is starting..."
          : "Backend is down... Starting.";
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("username");
    await prefs.remove("password");
    setState(() {}); // Refresh UI if needed
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: ValueListenableBuilder<String?>(
            valueListenable: _loginErrorNotifier,
            builder: (context, error, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error == null) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Logging you in...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ] else ...[
                    const Icon(Icons.cancel, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ]
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    _loginErrorNotifier.value = error;
    _showLoadingDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 180),
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("User id:", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: userController,
                  enabled: !_credentialsVerified,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Password:", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passController,
                  obscureText: _obscureText,
                  enabled: !_credentialsVerified,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: !_credentialsVerified
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen()),
                            );
                          }
                        : null,
                    child: const Text("Forgot Password",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_credentialsVerified ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    child:
                    const Text("Login", style: TextStyle(letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: !_credentialsVerified
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SignUpScreen()),
                              );
                            }
                          : null,
                      child: const Text("Signup",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Place the reset and verify boxes on either side of the secret button row, both as squares
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Reset square
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: TextButton(
                        onPressed: _credentialsVerified && !_isDeclined ? _resetRhythm : null,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.white),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    ),

                    // Rhythm tap buttons (like "Contact Us", etc.)
                    ..._buttonNames.map((name) => ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey[300]!;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                            if (states.contains(MaterialState.disabled)) {
                              return Colors.grey[600]!;
                            }
                            return Colors.blue[800]!;
                          },
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        textStyle: MaterialStateProperty.all(
                          const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                          ),
                        ),
                        elevation: MaterialStateProperty.all(0),
                        minimumSize: MaterialStateProperty.all(const Size(80, 40)),
                      ),
                      onPressed: _credentialsVerified && !_isDeclined
                          ? () {
                        _handleTap(name);
                      }
                          : null,
                      child: Text(
                        name, 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    )),

                    // Verify square
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _isVerifying ||
                            !_credentialsVerified ||
                            _isDeclined ||
                            _userSecretButton == null ||
                            _tapIntervals.isEmpty
                            ? null
                            : _verifyAndContinue,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.green),
                          foregroundColor: MaterialStateProperty.all(Colors.green),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}