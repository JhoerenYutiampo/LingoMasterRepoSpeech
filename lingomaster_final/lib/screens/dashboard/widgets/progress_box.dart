import 'package:flutter/material.dart';

class ProgressBox extends StatelessWidget {
  final String levelName;
  final double progress;
  final int completed;
  final int total;
  final VoidCallback? onTap;

  const ProgressBox({
    super.key,
    required this.levelName,
    required this.progress,
    required this.completed,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildProgressBar(),
                const SizedBox(height: 12),
                _buildStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            levelName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        _buildCompletionBadge(),
      ],
    );
  }

  Widget _buildCompletionBadge() {
    final isComplete = completed == total;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isComplete 
          ? Colors.green.withOpacity(0.2)
          : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green : Colors.blue,
          width: 1,
        ),
      ),
      child: Text(
        isComplete ? 'Complete!' : 'In Progress',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isComplete ? Colors.green : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
            minHeight: 12,
          ),
        ),
        if (progress > 0.12)
          Positioned.fill(
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1) return Colors.green;
    if (progress >= 0.7) return Colors.greenAccent;
    if (progress >= 0.4) return Colors.blueAccent;
    return Colors.blue;
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$completed/$total Questions",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        Text(
          "${total - completed} Remaining",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}