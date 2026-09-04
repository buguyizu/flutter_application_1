import 'package:flutter/material.dart';

class SmallDialColumn extends StatelessWidget {
  const SmallDialColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
