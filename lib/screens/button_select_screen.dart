import 'package:flutter/material.dart';

class ButtonSelectScreen extends StatefulWidget {
  final void Function(String) onButtonSelected;
  ButtonSelectScreen({required this.onButtonSelected});

  @override
  State<ButtonSelectScreen> createState() => _ButtonSelectScreenState();
}

class _ButtonSelectScreenState extends State<ButtonSelectScreen> {
  final List<String> buttonNames = [
    'Contact Us',
    'Feedback',
    'Help',
    'About',
    'Support',
  ];
  String? _selectedButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Select Your Secret Button', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose one button below as your secret button. You will need to tap your rhythm on this button during login.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ...buttonNames.map((name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedButton == name ? Colors.green : Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedButton = name;
                    });
                  },
                  child: Text(name),
                ),
              )),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _selectedButton == null
                    ? null
                    : () {
                        widget.onButtonSelected(_selectedButton!);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 