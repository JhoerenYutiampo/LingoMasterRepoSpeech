
import 'package:flutter/material.dart';

class PracticeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final VoidCallback onPressed;

  const PracticeButton({
    super.key,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCompleted 
          ? Border.all(color: Colors.green, width: 2)
          : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
