import 'package:flutter/material.dart';
import '../widgets/background_scaffold.dart';

class LockedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: const Center(
        child: Text(
          "Transaction Locked!",
          style: TextStyle(fontSize: 28, color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
