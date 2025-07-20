import 'package:flutter/material.dart';
import 'dart:math';
import 'access_granted_screen.dart';
import 'locked_screen.dart';
import '../widgets/background_scaffold.dart';

class GestureVerificationScreen extends StatefulWidget {
  @override
  _GestureVerificationScreenState createState() =>
      _GestureVerificationScreenState();
}

class _GestureVerificationScreenState extends State<GestureVerificationScreen> {
  List<Offset> points = [];
  DateTime? gestureStart;
  int failedAttempts = 0;

  void _onPanStart(DragStartDetails details) {
    gestureStart = DateTime.now();
    points = [details.localPosition];
  }

  void _onPanUpdate(DragUpdateDetails details) {
    points.add(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    final gestureDuration = DateTime.now().difference(gestureStart ?? DateTime.now());

    bool isValid = _is7Gesture(points);

    points.clear();

    // ✅ Require gesture to last at least 3 seconds
    if (isValid && gestureDuration.inSeconds >= 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AccessGrantedScreen()),
      );
    } else {
      failedAttempts++;
      if (failedAttempts >= 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LockedScreen()),
        );
      }
    }
  }

  bool _is7Gesture(List<Offset> pts) {
    if (pts.length < 5) return false;

    Offset start = pts.first;
    Offset mid = pts[pts.length ~/ 3];
    Offset end = pts.last;

    double dx1 = mid.dx - start.dx;
    double dy1 = mid.dy - start.dy;
    double dx2 = end.dx - mid.dx;
    double dy2 = end.dy - mid.dy;

    bool isHorizontal = dx1 > 80 && dy1.abs() < 40;
    bool isDiagonalDownLeft = dx2 < -40 && dy2 > 40;

    return isHorizontal && isDiagonalDownLeft;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: BackgroundScaffold(
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
