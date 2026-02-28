// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../services/market_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shimmer_card.dart';
import 'payment_screen.dart';
import 'paper_trading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fb  = FirebaseService();
  final _dev = DeviceService();
  final _mkt = MarketService();

  String?  _uuid;
  int      _selectedPackage = 1;
  int      _logoTapCount    = 0;
  DateTime? _firstLogoTap;

  // Ghost admin activation: 10 rapid taps on logo
  void _onLogoTap() {
    final now = DateTime.now();
    if (_firstLogoTap == null || now.difference(_firstLogoTap!) > const Duration(seconds: 10)) {
      _firstLogoTap = now;
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
      if (_logoTapCount >= 10) {
        _logoTapCount = 0;
        _showAdminPasswordDialog();
      }
    }
  }

  void _showAdminPasswordDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.obsidianCard,
        title: const Text('🔐 Admin Access',
            style: TextStyle(color: AppTheme.royalGold)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Master Password',
            hintText: 'Enter admin password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text == AppConstants.masterPassword) {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid password')),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  static const _packages = [
    SubscriptionPackage(
      id: 'monthly',
      name: 'SILVER',
      durationLabel: '1 Month Access',
      priceUSD: 29.99,
      priceSYP: '150,000 SYP',
      features: [
        'Daily VIP Signals (BTC/ETH)',
        'Whale Alert Notifications',
        'Paper Trading Simulator',
        'Telegram VIP Channel',
      ],
    ),
    SubscriptionPackage(
      id: 'quarterly',
      name: 'GOLD',
      durationLabel: '3 Months Access',
      priceUSD: 74.99,
      priceSYP: '380,000 SYP',
      features: [
        'Everything in Silver',
        'Premium Altcoin Signals',
        'Live Trade Alerts',
        'Priority Support 24/7',
        'Monthly Market Report',
      ],
      isMostPopular: true,
    ),
    SubscriptionPackage(
      id: 'yearly',
      name: 'DIAMOND',
      durationLabel: '12 Months Access',
      priceUSD: 199.99,
      priceSYP: '990,000 SYP',
      features: [
        'Everything in Gold',
        'One-on-One Consultation',
        'Portfolio Review (Monthly)',
        'Early Signal Access',
        'Exclusive DeFi Strategies',
        'Lifetime Discord Access',
      ],
    ),
  ];

  List<WhaleAlert> _whaleAlerts = [];

  @override
  void initState() {
    super.initState();
    _init();
    _mkt.whaleAlertStream().listen((alert) {
      if (!mounted) return;
      setState(() {
        _whaleAlerts = [alert, ..._whaleAlerts.take(4)];
      });
    });
  }

  Future<void> _init() async {
    _uuid = await _dev.getDeviceUUID();
    setState(() {});
  }

  Future<void> _onPadlockTap(bool isApproved, AppConfig cfg) async {
    if (isApproved) {
      final uri = Uri.parse(cfg.telegramLink);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PaymentScreen(
          selectedPackage: _packages[_selectedPackage],
          deviceUUID: _uuid!,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uuid == null) {
      return const Scaffold(
        backgroundColor: AppTheme.obsidianBlack,
        body: Center(child: CircularProgressIndicator(color: AppTheme.royalGold)),
      );
    }

    return StreamBuilder<AppConfig>(
      stream: _fb.configStream(),
      initialData: AppConfig.defaults(),
      builder: (context, cfgSnap) {
        final cfg = cfgSnap.data ?? AppConfig.defaults();

        return StreamBuilder<ApprovedDevice?>(
          stream: _fb.approvalStream(_uuid!),
          builder: (context, approvalSnap) {
            final approved   = approvalSnap.data;
            final isApproved = approved != null &&
                approved.expiresAt.isAfter(DateTime.now());

            return Scaffold(
              backgroundColor: AppTheme.obsidianBlack,
              floatingActionButton: _TelegramFAB(handle: cfg.supportHandle),
              body: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppTheme.obsidianBlack,
                    expandedHeight: 100,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.obsidianBlack, AppTheme.obsidianSurface],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: GestureDetector(
                            onTap: _onLogoTap,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 40),
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppTheme.goldGradient.createShader(b),
                                  child: const Text(
                                    '⚡ MarketMind Elite',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'VIP TRADING GROUP',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Live Ticker ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: LiveTickerBanner(items: _mkt.tickerItems),
                  ),

                  // ── Body Content ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Approval status banner
                          if (isApproved) _ApprovedBanner(expiry: approved!.expiresAt),
                          if (!isApproved) _PendingCheckBanner(uuid: _uuid!),

                          const SizedBox(height: 20),

                          // ── Subscription Cards ────────────────────
                          const _SectionHeader(title: '💎 Choose Your Plan'),
                          const SizedBox(height: 12),
                          ..._packages.asMap().entries.map((e) =>
                            GoldenSubscriptionCard(
                              package: e.value,
                              isSelected: e.key == _selectedPackage,
                              onTap: () => setState(() => _selectedPackage = e.key),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── VIP Button ────────────────────────────
                          GlowingPadlockButton(
                            isUnlocked: isApproved,
                            onTap: () => _onPadlockTap(isApproved, cfg),
                          ),
                          const SizedBox(height: 8),
                          if (!isApproved)
                            const Center(
                              child: Text(
                                'Select a plan and complete payment to unlock VIP',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          const SizedBox(height: 32),

                          // ── Paper Trading ─────────────────────────
                          _SectionHeader(
                            title: '🎮 Paper Trading Simulator',
                            trailing: TextButton(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    const PaperTradingScreen())),
                              child: const Text('Open →',
                                style: TextStyle(color: AppTheme.royalGold)),
                            ),
                          ),
                          const _PaperTradingTeaser(),
                          const SizedBox(height: 32),

                          // ── Whale Alerts ──────────────────────────
                          const _SectionHeader(title: '🐳 Whale Alert Feed'),
                          const SizedBox(height: 8),
                          if (_whaleAlerts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Monitoring blockchain movements...',
                                  style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                            )
                          else
                            ..._whaleAlerts.map((a) => WhaleAlertCard(alert: a)),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      )),
      if (trailing != null) trailing!,
    ],
  );
}

class _ApprovedBanner extends StatelessWidget {
  final DateTime expiry;
  const _ApprovedBanner({required this.expiry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.successGreen.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified, color: AppTheme.successGreen, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ VIP Access Activated',
                  style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w700)),
              Text('Expires: ${expiry.day}/${expiry.month}/${expiry.year}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PendingCheckBanner extends StatelessWidget {
  final String uuid;
  const _PendingCheckBanner({required this.uuid});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.obsidianCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
    ),
    child: const Row(
      children: [
        Icon(Icons.access_time, color: AppTheme.royalGold, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Complete payment to unlock VIP Telegram. Admin approval within 24h.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _PaperTradingTeaser extends StatelessWidget {
  const _PaperTradingTeaser();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        const Text('💰', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$1,000 Virtual Balance',
                style: TextStyle(color: AppTheme.royalGold,
                    fontWeight: FontWeight.w700, fontSize: 15)),
              Text('Trade BTC, ETH, SOL risk-free with live simulated prices.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('TRY',
            style: TextStyle(
                color: AppTheme.obsidianBlack,
                fontWeight: FontWeight.w900,
                fontSize: 12)),
        ),
      ],
    ),
  );
}

class _TelegramFAB extends StatelessWidget {
  final String handle;
  const _TelegramFAB({required this.handle});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    backgroundColor: const Color(0xFF229ED9),
    onPressed: () async {
      final uri = Uri.parse(handle);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    },
    child: const Icon(Icons.telegram, color: Colors.white, size: 28),
  );
}
