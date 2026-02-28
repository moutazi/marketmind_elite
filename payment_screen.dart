// lib/screens/payment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final SubscriptionPackage selectedPackage;
  final String deviceUUID;

  const PaymentScreen({
    super.key,
    required this.selectedPackage,
    required this.deviceUUID,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _fb      = FirebaseService();
  final _picker  = ImagePicker();

  // Form fields
  final _nameCtrl  = TextEditingController();
  final _txCtrl    = TextEditingController();
  File?   _receipt;
  bool    _loading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xf = await _picker.pickImage(source: ImageSource.gallery);
    if (xf != null) setState(() => _receipt = File(xf.path));
  }

  Future<void> _submit(String method, AppConfig cfg) async {
    if (_nameCtrl.text.trim().isEmpty) {
      _toast('Please enter your name');
      return;
    }
    if (_txCtrl.text.trim().isEmpty) {
      _toast('Please enter the transaction ID');
      return;
    }
    if (method == 'shamcash' && _receipt == null) {
      _toast('Please upload payment receipt');
      return;
    }

    setState(() => _loading = true);
    try {
      await _fb.submitPayment(
        deviceUUID: widget.deviceUUID,
        userName: _nameCtrl.text.trim(),
        packageId: widget.selectedPackage.id,
        paymentMethod: method,
        transactionId: _txCtrl.text.trim(),
        receiptImage: _receipt,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } catch (e) {
      _toast('Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  void _showSuccessDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.obsidianCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Payment Submitted!',
            style: TextStyle(color: AppTheme.royalGold,
                fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'Your payment is being reviewed.\nAdmin will approve within 24 hours and you will receive a push notification.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppConfig>(
      stream: _fb.configStream(),
      initialData: AppConfig.defaults(),
      builder: (context, snap) {
        final cfg = snap.data ?? AppConfig.defaults();

        return Scaffold(
          backgroundColor: AppTheme.obsidianBlack,
          appBar: AppBar(
            title: const Text('Complete Payment'),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.royalGold,
              labelColor: AppTheme.royalGold,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: '🇸🇾  Sham Cash'),
                Tab(text: '🌐  Payeer USDT'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _ShamCashTab(
                cfg: cfg,
                nameCtrl: _nameCtrl,
                txCtrl: _txCtrl,
                receipt: _receipt,
                onPickImage: _pickImage,
                loading: _loading,
                onSubmit: () => _submit('shamcash', cfg),
                package: widget.selectedPackage,
              ),
              _PayeerTab(
                cfg: cfg,
                nameCtrl: _nameCtrl,
                txCtrl: _txCtrl,
                loading: _loading,
                onSubmit: () => _submit('payeer', cfg),
                package: widget.selectedPackage,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sham Cash Tab ──────────────────────────────────────────────────────────
class _ShamCashTab extends StatelessWidget {
  final AppConfig cfg;
  final TextEditingController nameCtrl;
  final TextEditingController txCtrl;
  final File? receipt;
  final VoidCallback onPickImage;
  final bool loading;
  final VoidCallback onSubmit;
  final SubscriptionPackage package;

  const _ShamCashTab({
    required this.cfg, required this.nameCtrl, required this.txCtrl,
    required this.receipt, required this.onPickImage, required this.loading,
    required this.onSubmit, required this.package,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PackageSummary(package: package),
        const SizedBox(height: 24),

        // Sham Cash ID
        _InfoBox(
          title: '📱 Send to Sham Cash Number',
          value: cfg.shamCashId,
          canCopy: true,
        ),
        const SizedBox(height: 12),
        _InfoBox(
          title: '💵 Amount to Send',
          value: package.priceSYP,
          canCopy: false,
        ),
        const SizedBox(height: 24),

        const _FieldLabel(label: 'Your Full Name'),
        const SizedBox(height: 6),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'Transaction ID / Reference Number'),
        const SizedBox(height: 6),
        TextField(
          controller: txCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. 240612XXXX',
            prefixIcon: Icon(Icons.tag, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'Payment Receipt Screenshot'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.obsidianCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: receipt != null
                    ? AppTheme.royalGold
                    : AppTheme.royalGold.withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: receipt != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(receipt!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: AppTheme.royalGold.withOpacity(0.6), size: 40),
                      const SizedBox(height: 8),
                      const Text('Tap to upload receipt',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppTheme.obsidianBlack))
                : const Text('📤  Submit Payment Request'),
          ),
        ),
      ],
    ),
  );
}

// ── Payeer USDT Tab ────────────────────────────────────────────────────────
class _PayeerTab extends StatelessWidget {
  final AppConfig cfg;
  final TextEditingController nameCtrl;
  final TextEditingController txCtrl;
  final bool loading;
  final VoidCallback onSubmit;
  final SubscriptionPackage package;

  const _PayeerTab({
    required this.cfg, required this.nameCtrl, required this.txCtrl,
    required this.loading, required this.onSubmit, required this.package,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PackageSummary(package: package),
        const SizedBox(height: 24),

        // Network warning
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B0020),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFFF6B00), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'IMPORTANT: Send ONLY USDT on TRC20 network. Other networks will result in permanent loss.',
                  style: TextStyle(color: Color(0xFFFF6B00), fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _InfoBox(
          title: '💎 USDT (TRC20) Wallet Address',
          value: cfg.payeerAddress,
          canCopy: true,
        ),
        const SizedBox(height: 12),
        _InfoBox(
          title: '💵 Amount to Send',
          value: '\$${package.priceUSD.toStringAsFixed(2)} USDT',
          canCopy: false,
        ),
        const SizedBox(height: 24),

        const _FieldLabel(label: 'Your Full Name'),
        const SizedBox(height: 6),
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),

        const _FieldLabel(label: 'Transaction Hash (TXID)'),
        const SizedBox(height: 6),
        TextField(
          controller: txCtrl,
          decoration: const InputDecoration(
            hintText: 'Paste TRX transaction hash',
            prefixIcon: Icon(Icons.tag, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        const Text('You can find the TXID in your wallet transaction history.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: AppTheme.obsidianBlack))
                : const Text('📤  Submit Payment Request'),
          ),
        ),
      ],
    ),
  );
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────
class _PackageSummary extends StatelessWidget {
  final SubscriptionPackage package;
  const _PackageSummary({required this.package});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppTheme.goldCardGradient,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(package.name,
              style: const TextStyle(color: AppTheme.obsidianBlack,
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(package.durationLabel,
              style: TextStyle(color: AppTheme.obsidianBlack.withOpacity(0.7),
                  fontSize: 12)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${package.priceUSD.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.obsidianBlack,
                  fontWeight: FontWeight.w900, fontSize: 22)),
          Text(package.priceSYP,
              style: TextStyle(color: AppTheme.obsidianBlack.withOpacity(0.7),
                  fontSize: 11)),
        ]),
      ],
    ),
  );
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final bool canCopy;
  const _InfoBox({required this.title, required this.value, required this.canCopy});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.obsidianCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.royalGold.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
          child: Text(value, style: const TextStyle(
            color: AppTheme.royalGold,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          )),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.royalGold, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard ✓')),
              );
            },
          ),
      ]),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  );
}
