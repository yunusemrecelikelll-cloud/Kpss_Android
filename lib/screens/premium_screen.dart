import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();

    return Scaffold(
      appBar: AppBar(title: const Text('💎 Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (premium)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Premium hesabın aktif ✨', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => storage.setUserPlan('free'),
                      child: const Text('Ücretsiz Plan'),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _PricingCard(
                    title: 'Öğrenci Premium',
                    price: '50,00 TL',
                    onBuy: () => storage.setUserPlan('premium'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PricingCard(
                    title: 'Tam Premium',
                    price: '199,90 TL',
                    onBuy: () => storage.setUserPlan('premium'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const _FeatureTile(icon: '🧠', title: 'Yanlışlarımı Sına'),
          const _FeatureTile(icon: '♾️', title: 'Sınırsız Test'),
          const _FeatureTile(icon: '📊', title: 'Detaylı İstatistik'),
          const _FeatureTile(icon: '🎧', title: 'Sesli Özetler'),
          const _FeatureTile(icon: '⭐', title: 'VIP Rozet'),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title, price;
  final VoidCallback onBuy;
  const _PricingCard({required this.title, required this.price, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onBuy, child: const Text('Satın Al')),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String icon, title;
  const _FeatureTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Text(icon, style: const TextStyle(fontSize: 20)), title: Text(title)),
    );
  }
}
