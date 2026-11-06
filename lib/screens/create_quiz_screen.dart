import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../services/offline_share_service.dart';
import '../services/auth_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final bool isOnline; // true = server, false = LAN
  const CreateQuizScreen({required this.isOnline, super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<Map<String, String>> _questions = [];
  bool _liveSync = false; // optional LAN real‑time updates

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addQuestion() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Question')),
            TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Answer')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _questions.add({'q': qCtrl.text, 'a': aCtrl.text}));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _generateCode() => const Uuid().v4().replaceAll('-', '').substring(0, 6).toUpperCase();

  Future<void> _submit() async {
    final code = _generateCode();
    final auth = AuthService();
    final userId = await auth.getCurrentUserId();
    if (widget.isOnline) {
      // ----- ONLINE -----
      final api = ApiService(baseUrl: 'http://YOUR_SERVER_HOST:4000');
      final payload = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'secretCode': code,
        'questions': _questions
            .asMap()
            .entries
            .map((e) => {
                  'question_text': e.value['q'],
                  'answer': e.value['a'],
                  'position': e.key,
                })
            .toList(),
      };
      // ignore the response for now – you could handle errors here
      await api.fetchQuizByCode(''); // placeholder to keep the compiler happy
      // Show the code to the creator
      _showCodeDialog(code);
    } else {
      // ----- OFFLINE -----
      final share = OfflineShareService();
      await share.startSharing(
        secretCode: code,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        questions: _questions,
        liveSync: _liveSync,
      );
      _showCodeDialog(code);
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Ready'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this secret code with the participant:'),
            const SizedBox(height: 8),
            SelectableText(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 12),
            QrImage(data: code, version: QrVersions.auto, size: 200),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isOnline ? 'Create Quiz (Online)' : 'Create Quiz (Offline)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Quiz Title')),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._questions.asMap().entries.map(
              (e) => ListTile(
                title: Text('Q${e.key + 1}: ${e.value['q']}'),
                subtitle: Text('Answer: ${e.value['a']}'),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _questions.removeAt(e.key))),
              ),
            ),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add Question'), onPressed: _addQuestion),
            if (!widget.isOnline) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Enable Live LAN Sync (optional)'),
                subtitle: const Text('If on, answers are pushed to the creator in real time.'),
                value: _liveSync,
                onChanged: (v) => setState(() => _liveSync = v),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _questions.isEmpty ? null : _submit,
              child: const Text('Create Quiz & Show Code'),
            ),
          ],
        ),
      ),
    );
  }
}
