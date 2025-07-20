import 'package:flutter/material.dart';
import '../widgets/background_scaffold.dart';

class AccessGrantedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: const Center(
        child: Text(
          "Payment Successful!",
          style: TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
