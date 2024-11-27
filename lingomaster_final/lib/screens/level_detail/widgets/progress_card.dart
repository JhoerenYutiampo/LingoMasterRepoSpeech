import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int currentProgress;
  final int totalQuestions;

  const ProgressCard({
    super.key,
    required this.currentProgress,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentProgress / totalQuestions;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progress",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 15,
          ),
          const SizedBox(height: 4),
          Text(
            "$currentProgress / $totalQuestions",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}