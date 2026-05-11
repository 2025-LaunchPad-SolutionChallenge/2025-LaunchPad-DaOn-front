import 'package:flutter/material.dart';

class HomeWidget extends StatelessWidget {
  final String title;

  const HomeWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
