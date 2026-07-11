import 'package:flutter/material.dart';

class WrongBankScreen extends StatelessWidget {
  const WrongBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('❌ Yanlışlarım')),
      body: const Center(child: Text('Yakında')),
    );
  }
}
