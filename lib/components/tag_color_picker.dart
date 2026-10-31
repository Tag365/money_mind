import 'package:flutter/material.dart';

const List<Color> tagColors = [
  Color(0xFFFFC107),
  Color(0xFFFF9800),
  Color(0xFFFF5722),
  Color(0xFFF44336),
  Color(0xFF8E2C5A),
  Color(0xFFD500F9),
  Color(0xFF2962FF),
  Color(0xFF03A9F4),
  Color(0xFF00E5FF),
  Color(0xFF00E676),
  Color(0xFF4CAF50),
  Color(0xFF2E7D32),
  Color(0xFFFFEB3B),
  Color(0xFF283593),
  Color(0xFF9E9E9E),
];

/// Row of color dots; the selected one shows a check mark.
class TagColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const TagColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final color in tagColors)
          IconButton(
            tooltip: 'Tag color',
            icon: Icon(
              color == selected ? Icons.check_circle : Icons.circle,
              color: color,
            ),
            onPressed: () => onChanged(color),
          ),
      ],
    );
  }
}
