import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PaymentVerificationStatus { pending, paid, remindLater, cancelled }

/// Model representing a payment transaction awaiting verification.
class PendingPayment {
  final String id;
  final String recipientName;
  final double amount;
  final String upiId;
  final DateTime createdAt;
  bool isPaid;
  int reminderCount; // 0, 1, 2
  final int maxReminders;
  PaymentVerificationStatus status;

  PendingPayment({
    required this.id,
    required this.recipientName,
    required this.amount,
    required this.upiId,
    required this.createdAt,
    this.isPaid = false,
    this.reminderCount = 0,
    this.maxReminders = 2,
    this.status = PaymentVerificationStatus.pending,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientName': recipientName,
        'amount': amount,
        'upiId': upiId,
        'createdAt': createdAt.toIso8601String(),
        'isPaid': isPaid,
        'reminderCount': reminderCount,
        'maxReminders': maxReminders,
        'status': status.name,
      };

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        id: json['id'] as String,
        recipientName: json['recipientName'] as String,
        amount: (json['amount'] as num).toDouble(),
        upiId: json['upiId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        isPaid: json['isPaid'] as bool? ?? false,
        reminderCount: json['reminderCount'] as int? ?? 0,
        maxReminders: json['maxReminders'] as int? ?? 2,
        status: PaymentVerificationStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PaymentVerificationStatus.pending,
        ),
      );
}

class PaymentReminderService {
  static final PaymentReminderService _instance =
      PaymentReminderService._internal();
  factory PaymentReminderService() => _instance;
  PaymentReminderService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _upiKey = 'splitico_saved_user_upi_id';
  static const String _nameKey = 'splitico_saved_user_upi_name';
  static const String _pendingPaymentsKey = 'splitico_pending_payments';

  static final ValueNotifier<List<PendingPayment>> pendingPaymentsNotifier =
      ValueNotifier<List<PendingPayment>>([]);

  static bool _initialized = false;

  /// Global callback for when user marks payment from notification or UI
  static Function(PendingPayment payment)? onPaymentVerified;

  /// Initializes local notifications and loads pending payments
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );

    // Request Android 13+ Notification permission
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
    }

    await loadPendingPayments();
    _initialized = true;
  }

  @pragma('vm:entry-point')
  static void _backgroundNotificationHandler(
      NotificationResponse response) async {
    _handleResponseAction(response);
  }

  static void _onNotificationResponse(NotificationResponse response) async {
    _handleResponseAction(response);
  }

  static void _handleResponseAction(NotificationResponse response) async {
    final paymentId = response.payload;
    if (paymentId == null || paymentId.isEmpty) return;

    if (response.actionId == 'action_paid') {
      await markAsPaid(paymentId);
    } else if (response.actionId == 'action_remind_later') {
      await remindLater(paymentId);
    } else {
      // Notification tapped directly -> user can be shown the verification dialog
    }
  }

  // --- UPI ID Storage Helpers ---

  static Future<void> saveUserUpiId(String upiId, [String? name]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_upiKey, upiId.trim());
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_nameKey, name.trim());
    }
  }

  static Future<String?> getUserUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_upiKey);
  }

  static Future<String?> getUserUpiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // --- Pending Payments Management ---

  static Future<void> loadPendingPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_pendingPaymentsKey) ?? [];
    final payments = <PendingPayment>[];

    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        payments.add(PendingPayment.fromJson(map));
      } catch (e) {
        debugPrint('Error loading pending payment: $e');
      }
    }

    pendingPaymentsNotifier.value = payments;
  }

  static Future<void> _savePendingPayments(List<PendingPayment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = list.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_pendingPaymentsKey, rawList);
    pendingPaymentsNotifier.value = List.from(list);
  }

  /// Creates a new payment tracking flag & schedules the verification reminders (up to 2 times).
  static Future<PendingPayment> trackPayment({
    required String recipientName,
    required double amount,
    required String upiId,
    Duration firstReminderDelay = const Duration(minutes: 2),
  }) async {
    final id = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final payment = PendingPayment(
      id: id,
      recipientName: recipientName,
      amount: amount,
      upiId: upiId,
      createdAt: DateTime.now(),
      isPaid: false,
      reminderCount: 0,
      maxReminders: 2,
      status: PaymentVerificationStatus.pending,
    );

    final currentList = List<PendingPayment>.from(pendingPaymentsNotifier.value);
    currentList.insert(0, payment);
    await _savePendingPayments(currentList);

    // Schedule 1st notification reminder
    _scheduleLocalNotification(payment, delay: firstReminderDelay);

    return payment;
  }

  /// Mark payment as completed and cancel notifications
  static Future<void> markAsPaid(String paymentId) async {
    final currentList = List<PendingPayment>.from(pendingPaymentsNotifier.value);
    final index = currentList.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final payment = currentList[index];
      payment.isPaid = true;
      payment.status = PaymentVerificationStatus.paid;
      await _savePendingPayments(currentList);

      // Cancel notifications for this payment
      final notifId = payment.id.hashCode;
      await _notificationsPlugin.cancel(id: notifId);

      onPaymentVerified?.call(payment);
    }
  }

  /// Remind me later action (up to 2 times at the given period)
  static Future<void> remindLater(
    String paymentId, {
    Duration interval = const Duration(minutes: 5),
  }) async {
    final currentList = List<PendingPayment>.from(pendingPaymentsNotifier.value);
    final index = currentList.indexWhere((p) => p.id == paymentId);
    if (index != -1) {
      final payment = currentList[index];
      payment.reminderCount++;

      if (payment.reminderCount < payment.maxReminders) {
        payment.status = PaymentVerificationStatus.remindLater;
        await _savePendingPayments(currentList);

        // Schedule 2nd reminder
        _scheduleLocalNotification(payment, delay: interval);
      } else {
        // Reached maximum (2 times) reminders
        payment.status = PaymentVerificationStatus.pending;
        await _savePendingPayments(currentList);
      }
    }
  }

  /// Remove or cancel a tracked payment
  static Future<void> cancelPayment(String paymentId) async {
    final currentList = List<PendingPayment>.from(pendingPaymentsNotifier.value);
    currentList.removeWhere((p) => p.id == paymentId);
    await _savePendingPayments(currentList);
    await _notificationsPlugin.cancel(id: paymentId.hashCode);
  }

  /// Internal helper to send / schedule local notification with interactive action buttons
  static Future<void> _scheduleLocalNotification(
    PendingPayment payment, {
    Duration delay = const Duration(seconds: 1),
  }) async {
    Timer(delay, () async {
      // Double check if payment is still pending before notifying
      await loadPendingPayments();
      final current = pendingPaymentsNotifier.value.firstWhere(
        (p) => p.id == payment.id,
        orElse: () => payment,
      );

      if (current.isPaid) return;

      final notifId = payment.id.hashCode;
      final reminderLabel = payment.reminderCount > 0
          ? ' (Reminder ${payment.reminderCount + 1}/${payment.maxReminders})'
          : '';

      const androidDetails = AndroidNotificationDetails(
        'payment_reminders_channel',
        'Payment Reminders',
        channelDescription: 'Notifications to verify if pending UPI payments are completed',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_paid',
            'Paid ✓',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'action_remind_later',
            'Remind Later ⏰',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'payment_actions',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: notifId,
        title: '💸 Splitico Payment Check$reminderLabel',
        body: 'Is payment of ₹${payment.amount.toStringAsFixed(0)} to ${payment.recipientName} completed?',
        notificationDetails: notificationDetails,
        payload: payment.id,
      );
    });
  }

  /// Shows in-app bottom sheet or dialog to confirm pending payment
  static void showPaymentVerificationModal({
    required BuildContext context,
    required PendingPayment payment,
    VoidCallback? onSettled,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text('💸', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 8),
              Text(
                'Payment Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Is payment of ₹${payment.amount.toStringAsFixed(0)} to ${payment.recipientName} completed?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              if (payment.reminderCount > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Reminder ${payment.reminderCount + 1} of ${payment.maxReminders}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // 1. Paid Button
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await markAsPaid(payment.id);
                  onSettled?.call();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment of ₹${payment.amount.toStringAsFixed(0)} to ${payment.recipientName} marked as paid! 🎉',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'Paid ✓',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 2. Remind Me Later Button
              if (payment.reminderCount < payment.maxReminders)
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await remindLater(payment.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('We will remind you again later ⏰'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: Text(
                    payment.reminderCount == 0
                        ? 'Remind Me Later ⏰ (1 of 2)'
                        : 'Remind Me Later ⏰ (Final reminder)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
