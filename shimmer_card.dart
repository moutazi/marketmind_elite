// lib/widgets/shimmer_card.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';

// ── Golden Shimmer Subscription Card ──────────────────────────────────────
class GoldenSubscriptionCard extends StatefulWidget {
  final SubscriptionPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const GoldenSubscriptionCard({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<GoldenSubscriptionCard> createState() => _GoldenSubscriptionCardState();
}

class _GoldenSubscriptionCardState extends State<GoldenSubscriptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Shimmer.fromColors(
          baseColor:      AppTheme.royalGold,
          highlightColor: AppTheme.softGold,
          period: AppTheme.shimmerDuration,
          enabled: widget.isSelected || pkg.isMostPopular,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.goldCardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.isSelected ? AppTheme.goldGlow : AppTheme.subtleGlow,
              border: Border.all(
                color: widget.isSelected
                    ? AppTheme.royalGold
                    : AppTheme.deepGold.withOpacity(0.4),
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Subtle inner shimmer overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                            Colors.white.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pkg.name,
                                  style: const TextStyle(
                                    color: AppTheme.obsidianBlack,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  pkg.durationLabel,
                                  style: TextStyle(
                                    color: AppTheme.obsidianBlack.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${pkg.priceUSD.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppTheme.obsidianBlack,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  pkg.priceSYP,
                                  style: TextStyle(
                                    color: AppTheme.obsidianBlack.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (pkg.isMostPopular) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.obsidianBlack,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⭐ MOST POPULAR',
                              style: TextStyle(
                                color: AppTheme.royalGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Divider(color: AppTheme.obsidianBlack.withOpacity(0.2), height: 1),
                        const SizedBox(height: 12),
                        ...pkg.features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppTheme.obsidianBlack, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                f,
                                style: TextStyle(
                                  color: AppTheme.obsidianBlack.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                        if (widget.isSelected) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.obsidianBlack,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: AppTheme.royalGold, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'SELECTED',
                                    style: TextStyle(
                                      color: AppTheme.royalGold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live Ticker Banner ─────────────────────────────────────────────────────
class LiveTickerBanner extends StatefulWidget {
  final List<TickerItem> items;
  const LiveTickerBanner({super.key, required this.items});

  @override
  State<LiveTickerBanner> createState() => _LiveTickerBannerState();
}

class _LiveTickerBannerState extends State<LiveTickerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset>   _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _offset = Tween<Offset>(
      begin: const Offset(1, 0),
      end: const Offset(-3, 0),
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: AppTheme.obsidianSurface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: AppTheme.royalGold,
            child: const Text(
              '📡 LIVE',
              style: TextStyle(
                color: AppTheme.obsidianBlack,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ClipRect(
              child: SlideTransition(
                position: _offset,
                child: Row(
                  children: widget.items.map((t) => _tickerChip(t)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tickerChip(TickerItem t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.emoji),
        const SizedBox(width: 6),
        Text(
          t.pair,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          t.changeStr,
          style: TextStyle(
            color: t.isProfit ? AppTheme.successGreen : AppTheme.dangerRed,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

// ── Glowing Padlock Button ─────────────────────────────────────────────────
class GlowingPadlockButton extends StatefulWidget {
  final bool isUnlocked;
  final VoidCallback onTap;
  const GlowingPadlockButton({super.key, required this.isUnlocked, required this.onTap});

  @override
  State<GlowingPadlockButton> createState() => _GlowingPadlockButtonState();
}

class _GlowingPadlockButtonState extends State<GlowingPadlockButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  late final Animation<double>   _glowAnim;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 8, end: 24).animate(
      CurvedAnimation(parent: _glow, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _glowAnim,
    builder: (_, __) => GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.royalGold.withOpacity(0.6),
              blurRadius: widget.isUnlocked ? 8 : _glowAnim.value,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: AppTheme.obsidianBlack,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              widget.isUnlocked ? 'JOIN VIP TELEGRAM ✈️' : '🔒  UNLOCK VIP ACCESS',
              style: const TextStyle(
                color: AppTheme.obsidianBlack,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Whale Alert Card ───────────────────────────────────────────────────────
class WhaleAlertCard extends StatelessWidget {
  final WhaleAlert alert;
  const WhaleAlertCard({super.key, required this.alert});

  String _fmtAmount(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    return '\$${(v / 1000).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.obsidianCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.royalGold.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Text('🐳', style: TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmtAmount(alert.amount)} ${alert.coin} moved',
                style: const TextStyle(
                  color: AppTheme.royalGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '${alert.from} → ${alert.to}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '${alert.time.hour.toString().padLeft(2, '0')}:${alert.time.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}
