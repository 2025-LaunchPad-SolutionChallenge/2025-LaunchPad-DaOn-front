import 'package:flutter/material.dart';
import 'package:project_daon/ui/colorStyles.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('CommunityPage')),
      body: const Center(child: Text('CommunityPage Page')),
    );
  }
}
