import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_state.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<ApplicationState>();
    final uid = appState.user!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Please complete your profile to continue',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_controller.text.trim().isEmpty) return;

                      setState(() => _saving = true);

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                        'displayName': _controller.text.trim(),
                      });

                      setState(() => _saving = false);
                    },
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
