// lib/screens/paper_trading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/market_service.dart';
import '../utils/app_theme.dart';

class PaperTradingScreen extends StatefulWidget {
  const PaperTradingScreen({super.key});

  @override
  State<PaperTradingScreen> createState() => _PaperTradingScreenState();
}

class _PaperTradingScreenState extends State<PaperTradingScreen> {
  final _mkt = MarketService();

  double _balance = 1000.0;
  final List<PaperPosition> _positions = [];
  Map<String, double> _prices = {};
  StreamSubscription? _sub;

  String _selectedPair = 'BTC/USDT';
  final _qtyCtrl = TextEditingController(text: '0.01');

  @override
  void initState() {
    super.initState();
    _prices = _mkt.initialPrices;
    _sub = _mkt.priceTickStream().listen((p) {
      if (!mounted) return;
      setState(() {
        _prices = p;
        for (final pos in _positions) {
          pos.currentPrice = p[pos.pair] ?? pos.currentPrice;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _qtyCtrl.dispose();
    super.dispose();
  }

  double get _totalPnl =>
      _positions.fold(0.0, (acc, p) => acc + p.pnl);

  void _openPosition(String side) {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) return;
    final price = _prices[_selectedPair] ?? 0;
    final cost = price * qty;
    if (side == 'long' && cost > _balance) {
      _toast('Insufficient balance');
      return;
    }
    setState(() {
      if (side == 'long') _balance -= cost;
      _positions.add(PaperPosition(
        pair: _selectedPair,
        entryPrice: price,
        qty: qty,
        side: side,
        currentPrice: price,
      ));
    });
    _toast('${side.toUpperCase()} position opened on $_selectedPair');
  }

  void _closePosition(int index) {
    final pos = _positions[index];
    setState(() {
      _balance += (pos.side == 'long')
          ? pos.currentPrice * pos.qty
          : pos.entryPrice * pos.qty + pos.pnl;
      _positions.removeAt(index);
    });
    _toast('Position closed');
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBlack,
      appBar: AppBar(title: const Text('🎮 Paper Trading Simulator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance Bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.royalGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Virtual Balance',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('\$${_balance.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.royalGold,
                            fontSize: 24, fontWeight: FontWeight.w800)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Total P&L',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(
                      '${_totalPnl >= 0 ? '+' : ''}\$${_totalPnl.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _totalPnl >= 0
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Live Prices ──────────────────────────────────────────
            const Text('Live Prices',
                style: TextStyle(color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _prices.entries.map((e) {
                  final isSelected = e.key == _selectedPair;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPair = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppTheme.goldCardGradient
                            : AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.royalGold
                              : AppTheme.royalGold.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.obsidianBlack
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${e.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.obsidianBlack
                                  : AppTheme.royalGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Order Entry ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.obsidianCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trade $_selectedPair',
                      style: const TextStyle(color: AppTheme.royalGold,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('Qty: ',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _openPosition('long'),
                        child: const Text('📈 LONG'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dangerRed,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _openPosition('short'),
                        child: const Text('📉 SHORT'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Open Positions ───────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Open Positions',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text('${_positions.length} active',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            if (_positions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No open positions. Start trading!',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
              )
            else
              ..._positions.asMap().entries.map((e) => _PositionCard(
                position: e.value,
                onClose: () => _closePosition(e.key),
              )),
          ],
        ),
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final PaperPosition position;
  final VoidCallback onClose;

  const _PositionCard({required this.position, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isProfit = position.pnl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.obsidianCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfit
              ? AppTheme.successGreen.withOpacity(0.3)
              : AppTheme.dangerRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: position.side == 'long'
                  ? AppTheme.successGreen.withOpacity(0.2)
                  : AppTheme.dangerRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              position.side.toUpperCase(),
              style: TextStyle(
                color: position.side == 'long'
                    ? AppTheme.successGreen
                    : AppTheme.dangerRed,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(position.pair,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                Text(
                  'Entry: \$${position.entryPrice.toStringAsFixed(2)} | Now: \$${position.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '${isProfit ? '+' : ''}\$${position.pnl.toStringAsFixed(2)}',
              style: TextStyle(
                color: isProfit ? AppTheme.successGreen : AppTheme.dangerRed,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Text('Close',
                  style: TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
          ]),
        ],
      ),
    );
  }
}
