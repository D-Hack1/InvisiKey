import 'package:flutter/material.dart';
import '../widgets/background_scaffold.dart';

class PatternTrainingScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String password;

  const PatternTrainingScreen({
    required this.userId,
    required this.email,
    required this.password,
  });

  @override
  State<PatternTrainingScreen> createState() => _PatternTrainingScreenState();
}

class _PatternTrainingScreenState extends State<PatternTrainingScreen> {
  final int totalSamples = 10;
  int currentSample = 1;
  List<List<Offset>> gestureSamples = [];
  List<Offset> currentGesture = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentGesture = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentGesture.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentGesture.length < 2) return;

    setState(() {
      gestureSamples.add(List.from(currentGesture));
      currentGesture.clear();

      if (currentSample == totalSamples) {
        _showCompletionDialog();
      } else {
        currentSample++;
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Training Complete"),
        content: const Text("Gesture samples saved successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to previous screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    // TODO: Upload `gestureSamples` to backend or use for ML model training
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Gesture Training", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Draw your pattern ($currentSample/$totalSamples)",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: GesturePainter(currentGesture: currentGesture),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("User: ${widget.userId}", style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class GesturePainter extends CustomPainter {
  final List<Offset> currentGesture;

  GesturePainter({required this.currentGesture});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < currentGesture.length - 1; i++) {
      canvas.drawLine(currentGesture[i], currentGesture[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(GesturePainter oldDelegate) => true;
}
