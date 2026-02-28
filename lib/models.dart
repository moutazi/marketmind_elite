// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Subscription Package ───────────────────────────────────────────────────
class SubscriptionPackage {
  final String id;
  final String name;
  final String durationLabel;    // e.g. "1 Month"
  final double priceUSD;
  final String priceSYP;         // e.g. "150,000 SYP"
  final List<String> features;
  final bool isMostPopular;

  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.durationLabel,
    required this.priceUSD,
    required this.priceSYP,
    required this.features,
    this.isMostPopular = false,
  });
}

// ── Payment Request ────────────────────────────────────────────────────────
class PaymentRequest {
  final String id;
  final String deviceUUID;
  final String userName;
  final String packageId;
  final String paymentMethod;   // 'shamcash' | 'payeer'
  final String transactionId;
  final String? receiptImageUrl;
  final String status;          // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  PaymentRequest({
    required this.id,
    required this.deviceUUID,
    required this.userName,
    required this.packageId,
    required this.paymentMethod,
    required this.transactionId,
    this.receiptImageUrl,
    required this.status,
    required this.createdAt,
  });

  factory PaymentRequest.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentRequest(
      id: doc.id,
      deviceUUID: d['deviceUUID'] ?? '',
      userName: d['userName'] ?? '',
      packageId: d['packageId'] ?? '',
      paymentMethod: d['paymentMethod'] ?? '',
      transactionId: d['transactionId'] ?? '',
      receiptImageUrl: d['receiptImageUrl'],
      status: d['status'] ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'deviceUUID': deviceUUID,
    'userName': userName,
    'packageId': packageId,
    'paymentMethod': paymentMethod,
    'transactionId': transactionId,
    'receiptImageUrl': receiptImageUrl,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ── Approved Device ────────────────────────────────────────────────────────
class ApprovedDevice {
  final String deviceUUID;
  final String telegramLink;
  final DateTime approvedAt;
  final DateTime expiresAt;

  ApprovedDevice({
    required this.deviceUUID,
    required this.telegramLink,
    required this.approvedAt,
    required this.expiresAt,
  });

  factory ApprovedDevice.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ApprovedDevice(
      deviceUUID: d['deviceUUID'] ?? '',
      telegramLink: d['telegramLink'] ?? '',
      approvedAt: (d['approvedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ── App Config (from Firestore) ────────────────────────────────────────────
class AppConfig {
  final String shamCashId;
  final String payeerAddress;
  final String telegramLink;
  final String supportHandle;
  final Map<String, dynamic> packagePrices;

  AppConfig({
    required this.shamCashId,
    required this.payeerAddress,
    required this.telegramLink,
    required this.supportHandle,
    required this.packagePrices,
  });

  factory AppConfig.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppConfig(
      shamCashId: d['shamCashId'] ?? '',
      payeerAddress: d['payeerAddress'] ?? '',
      telegramLink: d['telegramLink'] ?? '',
      supportHandle: d['supportHandle'] ?? '',
      packagePrices: Map<String, dynamic>.from(d['packagePrices'] ?? {}),
    );
  }

  factory AppConfig.defaults() => AppConfig(
    shamCashId: '2095279480459286',
    payeerAddress: 'soon',
    telegramLink: 'soon',
    supportHandle: 'soon',
    packagePrices: {'monthly': 29.99, 'quarterly': 74.99, 'yearly': 199.99},
  );
}

// ── Live Ticker Item ───────────────────────────────────────────────────────
class TickerItem {
  final String pair;
  final double change;
  final String emoji;

  const TickerItem({required this.pair, required this.change, required this.emoji});

  bool get isProfit => change > 0;
  String get changeStr => '${isProfit ? '+' : ''}${change.toStringAsFixed(1)}%';
}

// ── Whale Alert ────────────────────────────────────────────────────────────
class WhaleAlert {
  final String coin;
  final double amount;
  final String from;
  final String to;
  final DateTime time;

  const WhaleAlert({
    required this.coin,
    required this.amount,
    required this.from,
    required this.to,
    required this.time,
  });
}

// ── Paper Trade Position ───────────────────────────────────────────────────
class PaperPosition {
  final String pair;
  final double entryPrice;
  final double qty;
  final String side; // 'long' | 'short'
  double currentPrice;

  PaperPosition({
    required this.pair,
    required this.entryPrice,
    required this.qty,
    required this.side,
    required this.currentPrice,
  });

  double get pnl {
    if (side == 'long') return (currentPrice - entryPrice) * qty;
    return (entryPrice - currentPrice) * qty;
  }
}
