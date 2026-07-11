import 'package:flutter/material.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎮 Oyunlar')),
      body: const Center(child: Text('Yakında')),
    );
  }
}
