import 'package:flutter/material.dart';
import 'create_quiz_screen.dart';
import 'answer_quiz_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_box),
              label: const Text('Create Quiz (Online)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateQuizScreen(isOnline: true)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Create Quiz (Offline)'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateQuizScreen(isOnline: false)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.question_answer),
              label: const Text('Answer a Quiz'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnswerQuizScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
