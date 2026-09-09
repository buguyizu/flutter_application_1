import 'package:flutter/material.dart';

class ClockToolbar extends StatelessWidget {
  const ClockToolbar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final toolbarSurface = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    return SizedBox(
      width: 166,
      child: Material(
        color: toolbarSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: 154,
            height: 74,
            child: GridView.count(
              crossAxisCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
