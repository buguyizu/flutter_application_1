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
      width: 98,
      child: Material(
        color: toolbarSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 90,
              height: 182,
              child: GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
