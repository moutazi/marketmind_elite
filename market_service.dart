// lib/services/market_service.dart
import 'dart:async';
import 'dart:math';
import '../models/models.dart';

class MarketService {
  static final MarketService _i = MarketService._();
  factory MarketService() => _i;
  MarketService._();

  final _rng = Random();

  // ── Simulated Live Ticker ──────────────────────────────────────────
  static const _staticTickers = [
    TickerItem(pair: 'BTC/USDT', change: 150.4,  emoji: '🟢'),
    TickerItem(pair: 'ETH/USDT', change: 87.2,   emoji: '🟢'),
    TickerItem(pair: 'SOL/USDT', change: -12.3,  emoji: '🔴'),
    TickerItem(pair: 'BNB/USDT', change: 45.6,   emoji: '🟢'),
    TickerItem(pair: 'XRP/USDT', change: 220.1,  emoji: '🟢'),
    TickerItem(pair: 'DOGE/USDT',change: -8.9,   emoji: '🔴'),
    TickerItem(pair: 'ADA/USDT', change: 33.7,   emoji: '🟢'),
    TickerItem(pair: 'MATIC/USDT',change: 115.5, emoji: '🟢'),
    TickerItem(pair: 'AVAX/USDT',change: -5.2,   emoji: '🔴'),
    TickerItem(pair: 'LINK/USDT',change: 67.9,   emoji: '🟢'),
  ];

  List<TickerItem> get tickerItems => _staticTickers;

  // ── Simulated Whale Alerts ─────────────────────────────────────────
  Stream<WhaleAlert> whaleAlertStream() async* {
    final coins   = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP'];
    final wallets = ['Binance', 'Coinbase', 'Unknown Whale', 'OKX', 'Bybit'];

    while (true) {
      await Future.delayed(Duration(seconds: 8 + _rng.nextInt(12)));
      yield WhaleAlert(
        coin:   coins[_rng.nextInt(coins.length)],
        amount: 500000 + _rng.nextDouble() * 50000000,
        from:   wallets[_rng.nextInt(wallets.length)],
        to:     wallets[_rng.nextInt(wallets.length)],
        time:   DateTime.now(),
      );
    }
  }

  // ── Paper Trading Simulator ────────────────────────────────────────
  static const _prices = {
    'BTC/USDT': 43500.0,
    'ETH/USDT': 2650.0,
    'SOL/USDT': 98.0,
    'BNB/USDT': 315.0,
  };

  Map<String, double> get initialPrices => Map.from(_prices);

  Stream<Map<String, double>> priceTickStream() async* {
    final prices = Map<String, double>.from(_prices);
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      prices.updateAll((k, v) => v * (1 + (_rng.nextDouble() - 0.5) * 0.002));
      yield Map.from(prices);
    }
  }
}
