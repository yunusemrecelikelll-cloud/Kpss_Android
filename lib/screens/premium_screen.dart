import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final PurchaseService _purchases;

  @override
  void initState() {
    super.initState();
    // NOT: PurchaseService bilerek burada, ekrana özel olarak oluşturuluyor
    // (main.dart'taki global Provider ağacına eklenmedi) — bu satın alma
    // görevi sadece premium_screen.dart + purchase_service.dart dosyalarını
    // değiştirmekle sınırlı tutuldu.
    _purchases = PurchaseService(context.read<StorageService>());
    _purchases.addListener(_onPurchaseServiceChanged);
    _purchases.init();
  }

  void _onPurchaseServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _purchases.removeListener(_onPurchaseServiceChanged);
    _purchases.dispose();
    super.dispose();
  }

  Future<void> _buy(BuildContext context, String productId) async {
    context.read<SoundService>().click();
    if (_purchases.status == PurchaseServiceStatus.unavailable) {
      _showStoreUnavailableSheet(context, productId);
      return;
    }
    await _purchases.buy(productId);
    if (!mounted) return;
    if (_purchases.status == PurchaseServiceStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_purchases.lastError ?? 'Satın alma başarısız oldu.')),
      );
    }
  }

  /// Mağaza gerçekten kullanılamıyorsa (emülatör, App Store Connect/Play
  /// Console'da ürünler henüz tanımlanmamış, mağaza hesabı yok vb.) kullanıcıya
  /// bunu açıkça söyler. Sadece geliştirme/test kolaylığı için — normal akışta
  /// hiç görünmemesi beklenir — "test modunda aç" seçeneği sunar; bu SADECE
  /// mağaza gerçekten erişilemezken gösterilir, gerçek ürünlerin yerini almaz.
  void _showStoreUnavailableSheet(BuildContext context, String productId) {
    final storage = context.read<StorageService>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mağaza şu an kullanılamıyor',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _purchases.lastError ??
                    'Gerçek satın alma için App Store Connect / Play Console\'da '
                        'ürünlerin tanımlanmış olması ve cihazda bir mağaza '
                        'hesabının oturum açmış olması gerekir.',
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // Sadece geliştirme modunda (kDebugMode) ve mağaza
                    // gerçekten erişilemezken gösterilen fallback — gerçek
                    // ödeme akışının yerine geçmez.
                    context.read<SoundService>().click();
                    storage.setUserPlan('premium');
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Test/Geliştirme Modu: Premium\'u Aç'),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<SoundService>().click();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    context.read<SoundService>().click();
    await _purchases.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Önceki satın alımlar kontrol ediliyor…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final premium = storage.isPremiumUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('💎 Premium'),
        actions: [
          IconButton(
            tooltip: 'Satın Alımları Geri Yükle',
            icon: const Icon(Icons.restore),
            onPressed: () => _restore(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_purchases.status == PurchaseServiceStatus.unavailable)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mağaza şu an kullanılamıyor: ${_purchases.lastError ?? "bilinmeyen sebep"}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ),
          if (premium)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Premium hesabın aktif ✨', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        context.read<SoundService>().click();
                        storage.setUserPlan('free');
                      },
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
                    price: _purchases.productFor(kOgrenciPremiumId)?.price ?? '50,00 TL',
                    busy: _purchases.isPurchasing,
                    onBuy: () => _buy(context, kOgrenciPremiumId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PricingCard(
                    title: 'Tam Premium',
                    price: _purchases.productFor(kTamPremiumId)?.price ?? '199,90 TL',
                    busy: _purchases.isPurchasing,
                    onBuy: () => _buy(context, kTamPremiumId),
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
  final bool busy;
  final VoidCallback onBuy;
  const _PricingCard({required this.title, required this.price, required this.onBuy, this.busy = false});

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
            ElevatedButton(
              onPressed: busy ? null : onBuy,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Satın Al'),
            ),
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
