import 'package:flutter/material.dart';

class HeartDialog extends StatelessWidget {
  const HeartDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('No Hearts Left'),
      content: const Text(
        'You have no hearts left. Practice or Complete questions to earn more.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}