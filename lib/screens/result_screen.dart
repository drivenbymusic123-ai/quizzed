import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final int correct;
  final int total;

  const ResultScreen({required this.correct, required this.total, super.key});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (correct / total * 100).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $correct / $total', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Percentage: $percent %', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
