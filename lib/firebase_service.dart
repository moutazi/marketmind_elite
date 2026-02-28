// lib/services/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class FirebaseService {
  static final FirebaseService _i = FirebaseService._();
  factory FirebaseService() => _i;
  FirebaseService._();

  final _db  = FirebaseFirestore.instance;
  final _st  = FirebaseStorage.instance;
  final _fcm = FirebaseMessaging.instance;

  // ── Collections ────────────────────────────────────────────────────
  CollectionReference get _payments  => _db.collection('payment_requests');
  CollectionReference get _approved  => _db.collection('approved_devices');
  DocumentReference  get _config    => _db.collection('config').doc('app_config');

  // ── App Config (real-time) ─────────────────────────────────────────
  Stream<AppConfig> configStream() => _config.snapshots().map(
    (s) => s.exists ? AppConfig.fromFirestore(s) : AppConfig.defaults(),
  );

  Future<AppConfig> getConfig() async {
    final s = await _config.get();
    return s.exists ? AppConfig.fromFirestore(s) : AppConfig.defaults();
  }

  Future<void> updateConfig(Map<String, dynamic> fields) =>
      _config.set(fields, SetOptions(merge: true));

  // ── Device Approval ────────────────────────────────────────────────
  Stream<ApprovedDevice?> approvalStream(String uuid) =>
      _approved.doc(uuid).snapshots().map(
        (s) => s.exists ? ApprovedDevice.fromFirestore(s) : null,
      );

  Future<bool> isDeviceApproved(String uuid) async {
    final doc = await _approved.doc(uuid).get();
    if (!doc.exists) return false;
    final d = doc.data() as Map<String, dynamic>;
    final exp = (d['expiresAt'] as Timestamp?)?.toDate();
    return exp != null && exp.isAfter(DateTime.now());
  }

  Future<void> approveDevice({
    required String uuid,
    required String telegramLink,
    required int durationDays,
    required String fcmToken,
  }) async {
    final now = DateTime.now();
    await _approved.doc(uuid).set({
      'deviceUUID': uuid,
      'telegramLink': telegramLink,
      'approvedAt': now,
      'expiresAt': now.add(Duration(days: durationDays)),
    });

    // Update payment request status
    final qs = await _payments.where('deviceUUID', isEqualTo: uuid)
        .where('status', isEqualTo: 'pending').get();
    for (final doc in qs.docs) {
      await doc.reference.update({'status': 'approved'});
    }

    // Send push notification
    if (fcmToken.isNotEmpty) {
      // FCM send via Admin SDK (call Cloud Function or direct HTTP)
      // Handled by Cloud Function trigger on approved_devices write
    }
  }

  Future<void> rejectPayment(String paymentId) =>
      _payments.doc(paymentId).update({'status': 'rejected'});

  // ── Payment Submission ─────────────────────────────────────────────
  Future<String> submitPayment({
    required String deviceUUID,
    required String userName,
    required String packageId,
    required String paymentMethod,
    required String transactionId,
    File? receiptImage,
  }) async {
    String? imageUrl;

    if (receiptImage != null) {
      imageUrl = await _uploadReceiptImage(receiptImage, deviceUUID);
    }

    final docRef = _payments.doc();
    await docRef.set({
      'deviceUUID': deviceUUID,
      'userName': userName,
      'packageId': packageId,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'receiptImageUrl': imageUrl,
      'status': 'pending',
      'fcmToken': await _fcm.getToken() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ── Image Upload (with compression) ───────────────────────────────
  Future<String> _uploadReceiptImage(File file, String uuid) async {
    // Compress to stay under Firebase free tier limits
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/receipt_compressed_$uuid.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,          // Aggressive compression for storage savings
      minWidth: 800,
      minHeight: 600,
    );

    final ref = _st.ref('receipts/$uuid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = await ref.putFile(compressed ?? file);
    return await task.ref.getDownloadURL();
  }

  // ── Pending Payments (Admin) ───────────────────────────────────────
  Stream<List<PaymentRequest>> pendingPaymentsStream() =>
      _payments.where('status', isEqualTo: 'pending')
               .orderBy('createdAt', descending: true)
               .snapshots()
               .map((qs) => qs.docs.map(PaymentRequest.fromFirestore).toList());

  // ── FCM Setup ──────────────────────────────────────────────────────
  Future<void> initFCM() async {
    await _fcm.requestPermission();
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  Future<String?> getFCMToken() => _fcm.getToken();
}
