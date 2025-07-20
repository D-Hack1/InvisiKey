import 'package:flutter/material.dart';
import 'package:prototypebank/screens/maintenance_screen.dart';
import '../screens/send_money_screen.dart';
import '../widgets/background_scaffold.dart';
import '../screens/send_money_screen1.dart';
import '../screens/balance_screen.dart';
import '../screens/card_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../screens/bill_payment_screen.dart';
import '../screens/MyProfileScreen.dart';
import 'main_navigation_screen.dart';
import '../../main.dart'; // Import the rootNavigatorKey

class HomeScreen extends StatelessWidget {
  final double balance = 2530.00;

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
              },
              child: const Text(
                "NO",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                _showLogoutBuffering(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "YES",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutBuffering(BuildContext context) {
    // Use a builder to capture the dialog's context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(dialogContext, rootNavigator: true).pop(); // Close the buffering dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logoutWithGlobalKey();
          });
        });
        return Dialog(
          backgroundColor: Colors.blue.shade500.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Logging out...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logoutWithGlobalKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("username");
    await prefs.remove("password");
    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildSectionTitle(String title, {bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color:Colors.white)),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("New",
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: Colors.blue, ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
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
          automaticallyImplyLeading: false, // to avoid default back arrow
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.account_balance, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                "Canara Bank",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.blue, size: 28),
              tooltip: "Logout",
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),


        body: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App logo and name

                const SizedBox(height: 20),

                // View Balance card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo[900],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Text("View Balance",
                          style:
                          TextStyle(color: Colors.white, fontSize: 20)),
                      const SizedBox(height: 10),
                      Text("XXXXX",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showLoadingAndNavigateWithFade(
                            context,
                            BalanceScreen(balance: balance),
                            message: "Fetching balance...",
                          );
                        },

                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: Text("Show Balance", style: TextStyle(color: Colors.indigo[900])),
                      ),

                      const SizedBox(height: 10),
                      const Text("Open FD/RD | NEFT/RTGS | LOANS",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sections
                _buildSectionTitle("FUNDS TRANSFER"),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _buildGridItem("With-in\nCanara", Icons.sync_alt,onTap: () {
                      _showLoadingAndNavigateWithFade(context, SendMoneyScreen(), message: "Redirecting to Funds Transfer...");
                    },
                    ),
                    _buildGridItem("Other Banks\n(IMPS)", Icons.account_balance, onTap: () {
                      _showLoadingAndNavigateWithFade(context, SendMoneyScreen1(), message: "Redirecting to Funds Transfer...");
                    }),

                    _buildGridItem("Card-less\nCash", Icons.atm, onTap: () {
                      _showLoadingAndNavigateWithFade(context, MaintenanceScreen(), message: "Redirecting to  Card-Less cash...");
                    },
                    ),
                  ],
                ),


                _buildSectionTitle("SERVICES"),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _buildGridItem("Manage\nAccounts", Icons.manage_accounts),
                    _buildGridItem("Transaction\nHistory", Icons.history),
                    _buildGridItem("Manage\nBeneficiary", Icons.group_add),
                    _buildGridItem("Non-Financial\nServices", Icons.settings),
                    _buildGridItem("Donation", Icons.volunteer_activism),
                    _buildGridItem("Insurance", Icons.health_and_safety),
                  ],
                ),

                _buildSectionTitle("LIFE STYLE", isNew: true),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _buildGridItem("Bus", Icons.directions_bus),
                    _buildGridItem("Recharge", Icons.phone_android),
                    _buildGridItem("Flights", Icons.flight),
                  ],
                ),

                _buildSectionTitle("GOVT. SCHEMES"),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _buildGridItem("Atal Pension", Icons.security),
                    _buildGridItem("Submit Pensioner", Icons.assignment),
                    _buildGridItem("Re-generate Tax", Icons.refresh),
                  ],
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }
  void _showLoadingAndNavigate(BuildContext context, Widget screen, {String message = "Please wait..."}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.blue.shade500.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context); // close dialog
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
  void _showLoadingAndNavigateWithFade(BuildContext context, Widget screen, {String message = "Please wait..."}) async {
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
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context); // Close loading dialog

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ));
  }

}