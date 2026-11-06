import 'package:flutter/material.dart';

class AnswerQuizScreen extends StatelessWidget {
  const AnswerQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Quiz')),
      body: const Center(
        child: Text('Quiz answering UI goes here'),
      ),
    );
  }
}
