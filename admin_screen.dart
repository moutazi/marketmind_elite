// lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final _fb = FirebaseService();
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.obsidianBlack,
    appBar: AppBar(
      title: const Text('👁  Ghost Admin Panel'),
      backgroundColor: AppTheme.obsidianSurface,
      bottom: TabBar(
        controller: _tab,
        indicatorColor: AppTheme.royalGold,
        labelColor: AppTheme.royalGold,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: '⏳ Pending'),
          Tab(text: '⚙️  Settings'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        const _PendingTab(),
        _SettingsTab(fb: _fb),
      ],
    ),
  );
}

// ── Pending Payments Tab ───────────────────────────────────────────────────
class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService();

    return StreamBuilder<List<PaymentRequest>>(
      stream: fb.pendingPaymentsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              color: AppTheme.royalGold));
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✅', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('No pending requests',
                    style: TextStyle(color: AppTheme.textSecondary,
                        fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) => _PendingCard(request: requests[i]),
        );
      },
    );
  }
}

class _PendingCard extends StatefulWidget {
  final PaymentRequest request;
  const _PendingCard({required this.request});

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  final _fb = FirebaseService();
  bool _processing = false;

  Future<void> _approve() async {
    setState(() => _processing = true);
    try {
      // Fetch current telegram link from config
      final cfg = await _fb.getConfig();
      final durationDays = _durationForPackage(widget.request.packageId);

      await _fb.approveDevice(
        uuid: widget.request.deviceUUID,
        telegramLink: cfg.telegramLink,
        durationDays: durationDays,
        fcmToken: '',  // populated from payment request in full impl
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Device approved! Push notification sent.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    await _fb.rejectPayment(widget.request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Payment rejected')),
    );
  }

  int _durationForPackage(String id) {
    switch (id) {
      case 'monthly':   return 30;
      case 'quarterly': return 90;
      case 'yearly':    return 365;
      default:          return 30;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: AppTheme.obsidianCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.royalGold.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppTheme.obsidianSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AppTheme.royalGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.request.userName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              _PackageBadge(id: widget.request.packageId),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Method', value: widget.request.paymentMethod.toUpperCase()),
              _InfoRow(label: 'TX ID',  value: widget.request.transactionId),
              _InfoRow(
                label: 'Device UUID',
                value: '${widget.request.deviceUUID.substring(0, 12)}...',
              ),
              _InfoRow(
                label: 'Date',
                value: '${widget.request.createdAt.day}/'
                    '${widget.request.createdAt.month}/'
                    '${widget.request.createdAt.year}',
              ),

              // Receipt image
              if (widget.request.receiptImageUrl != null) ...[
                const SizedBox(height: 12),
                const Text('Receipt:',
                    style: TextStyle(color: AppTheme.textSecondary,
                        fontSize: 12)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showFullImage(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.request.receiptImageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 140,
                        color: AppTheme.obsidianSurface,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.royalGold, strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Tap to enlarge',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _processing ? null : _approve,
                    icon: _processing
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('APPROVE', style: TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed,
                      side: const BorderSide(color: AppTheme.dangerRed),
                    ),
                    onPressed: _reject,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('REJECT', style: TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    ),
  );

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: CachedNetworkImage(
          imageUrl: widget.request.receiptImageUrl!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ── Settings Tab ───────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  final FirebaseService fb;
  const _SettingsTab({required this.fb});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _shamCtrl      = TextEditingController();
  final _payeerCtrl    = TextEditingController();
  final _telegramCtrl  = TextEditingController();
  final _supportCtrl   = TextEditingController();
  final _priceMonthly  = TextEditingController();
  final _priceQuarterly= TextEditingController();
  final _priceYearly   = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final cfg = await widget.fb.getConfig();
    _shamCtrl.text       = cfg.shamCashId;
    _payeerCtrl.text     = cfg.payeerAddress;
    _telegramCtrl.text   = cfg.telegramLink;
    _supportCtrl.text    = cfg.supportHandle;
    _priceMonthly.text   = cfg.packagePrices['monthly']?.toString() ?? '29.99';
    _priceQuarterly.text = cfg.packagePrices['quarterly']?.toString() ?? '74.99';
    _priceYearly.text    = cfg.packagePrices['yearly']?.toString() ?? '199.99';
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.fb.updateConfig({
        'shamCashId':    _shamCtrl.text.trim(),
        'payeerAddress': _payeerCtrl.text.trim(),
        'telegramLink':  _telegramCtrl.text.trim(),
        'supportHandle': _supportCtrl.text.trim(),
        'packagePrices': {
          'monthly':   double.tryParse(_priceMonthly.text) ?? 29.99,
          'quarterly': double.tryParse(_priceQuarterly.text) ?? 74.99,
          'yearly':    double.tryParse(_priceYearly.text) ?? 199.99,
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Settings updated in real-time!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SettingsSection(title: '🇸🇾 Sham Cash'),
        _AdminField(ctrl: _shamCtrl, label: 'Sham Cash Phone Number'),
        const SizedBox(height: 20),

        const _SettingsSection(title: '🌐 Payeer USDT'),
        _AdminField(ctrl: _payeerCtrl, label: 'TRC20 Wallet Address'),
        const SizedBox(height: 20),

        const _SettingsSection(title: '✈️ Telegram'),
        _AdminField(ctrl: _telegramCtrl, label: 'VIP Telegram Link'),
        _AdminField(ctrl: _supportCtrl,  label: 'Support Handle URL'),
        const SizedBox(height: 20),

        const _SettingsSection(title: '💲 Package Prices (USD)'),
        _AdminField(ctrl: _priceMonthly,   label: 'Monthly Price',   keyboard: TextInputType.number),
        _AdminField(ctrl: _priceQuarterly, label: 'Quarterly Price', keyboard: TextInputType.number),
        _AdminField(ctrl: _priceYearly,    label: 'Yearly Price',    keyboard: TextInputType.number),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppTheme.obsidianBlack))
                : const Icon(Icons.cloud_upload_outlined),
            label: const Text('💾  SAVE & PUSH LIVE',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 20),

        const Center(
          child: Text(
            'Changes apply to ALL users in real-time via Firebase.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

// ── Reusable admin widgets ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text('$label: ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _PackageBadge extends StatelessWidget {
  final String id;
  const _PackageBadge({required this.id});

  Color get _color => id == 'yearly'
      ? const Color(0xFF4FC3F7)
      : id == 'quarterly'
          ? AppTheme.royalGold
          : AppTheme.textSecondary;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _color.withOpacity(0.4)),
    ),
    child: Text(
      id.toUpperCase(),
      style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  final String title;
  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(
      color: AppTheme.royalGold, fontWeight: FontWeight.w700, fontSize: 14)),
  );
}

class _AdminField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboard;

  const _AdminField({
    required this.ctrl,
    required this.label,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(labelText: label),
    ),
  );
}
