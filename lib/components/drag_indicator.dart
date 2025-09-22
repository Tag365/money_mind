import 'package:flutter/material.dart';

class DragIndicator extends StatelessWidget {
  const DragIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 60,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}