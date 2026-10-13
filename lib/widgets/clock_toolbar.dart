import 'package:flutter/material.dart';

class ClockToolbar extends StatelessWidget {
  const ClockToolbar({
    super.key,
    required this.children,
    this.crossAxisCount = 4,
    this.width = 166,
  });

  final List<Widget> children;
  final int crossAxisCount;
  final double width;

  @override
  Widget build(BuildContext context) {
    final toolbarSurface = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    const gridSpacing = 6.0;
    final gridWidth = width - 12;
    final rowCount = (children.length / crossAxisCount).ceil();
    final tileExtent =
        (gridWidth - gridSpacing * (crossAxisCount - 1)) / crossAxisCount;
    final gridHeight = rowCount * tileExtent + gridSpacing * (rowCount - 1);
    return SizedBox(
      width: width,
      child: Material(
        color: toolbarSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1,
              crossAxisSpacing: gridSpacing,
              mainAxisSpacing: gridSpacing,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
