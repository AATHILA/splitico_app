import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class UpiPaymentService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.splitico/upi_pay',
  );

  /// Direct pay action triggered when clicking the "Pay" button.
  /// Bypasses intermediate payment method bottom sheet, launches
  /// Android's native system UPI app chooser dialog, and shows the
  /// confirmation dialog ONLY when the user returns to Splitico.
  static Future<void> directPay({
    required BuildContext context,
    required String name,
    required double amount,
    required String upiId,
    VoidCallback? onSettled,
  }) async {
    final cleanUpiId = upiId.trim();
    if (cleanUpiId.isEmpty || !cleanUpiId.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid UPI ID for $name (e.g. name@oksbi)',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool launched = false;
    try {
      launched = await pay(upiId: cleanUpiId, name: name, amount: amount);
    } catch (e) {
      debugPrint('UPI launch error: $e');
    }

    if (!context.mounted) return;

    if (launched) {
      // Ensure the app has returned to resumed state before presenting dialog
      await _waitForAppReturn();
      if (!context.mounted) return;

      _showPaymentConfirmationDialog(
        context: context,
        name: name,
        amount: amount,
        upiId: cleanUpiId,
        onSettled: onSettled,
      );
    } else {
      _showUpiFallbackDialog(
        context: context,
        name: name,
        upiId: cleanUpiId,
        amount: amount,
        onSettled: onSettled,
      );
    }
  }

  /// Helper to wait until the app returns to foreground (resumed state).
  static Future<void> _waitForAppReturn() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return;
      }
    }

    final completer = Completer<void>();
    late final AppLifecycleListener listener;

    listener = AppLifecycleListener(
      onResume: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    await Future.any([
      completer.future,
      Future.delayed(const Duration(minutes: 5)),
    ]);

    listener.dispose();
  }

  /// Builds a standard NPCI compliant P2P UPI payment URI String.
  static String buildUriString({
    required String upiId,
    required String name,
    required double amount,
    String? note,
    String? txnRef,
  }) {
    final cleanUpiId = upiId.trim();
    final cleanName = name.trim();
    final cleanNote = (note ?? 'Splitico Settlement').trim();
    final formattedAmount = amount.toStringAsFixed(2);

    final uriBuffer = StringBuffer(
      'upi://pay'
      '?pa=$cleanUpiId'
      '&pn=${Uri.encodeComponent(cleanName)}'
      '&am=$formattedAmount'
      '&cu=INR'
      '&tn=${Uri.encodeComponent(cleanNote)}',
    );

    // NPCI UPI Guideline: 'tr' (Transaction Ref ID) is strictly for Merchant (P2M) transactions.
    // For P2P peer-to-peer payments, passing a custom 'tr' causes UPI apps (GPay, PhonePe, Paytm)
    // to fail with "Invalid Transaction Reference" because the payee VPA is a personal account.
    if (txnRef != null && txnRef.trim().isNotEmpty) {
      uriBuffer.write('&tr=${Uri.encodeComponent(txnRef.trim())}');
    }

    return uriBuffer.toString();
  }

  /// Builds a standard NPCI compliant P2P UPI payment Uri object.
  static Uri buildUri({
    required String upiId,
    required String name,
    required double amount,
    String? note,
  }) {
    return Uri.parse(
      buildUriString(upiId: upiId, name: name, amount: amount, note: note),
    );
  }

  /// Attempts to launch the UPI intent directly via native MethodChannel chooser,
  /// opening Android's native app selector (GPay, PhonePe, Paytm, BHIM, etc.).
  static Future<bool> pay({
    required String upiId,
    required String name,
    required double amount,
    String? note,
  }) async {
    debugPrint('UPI ID: $upiId');
    debugPrint('Name: $name');
    debugPrint('Amount: $amount');

    final urlString = buildUriString(
      upiId: upiId,
      name: name,
      amount: amount,
      note: note,
    );
    debugPrint('UPI URI: $urlString');

    // 1. Try Android native Intent.createChooser via MethodChannel
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'launchUpiChooser',
        {'uri': urlString},
      );
      if (result == true) return true;
    } catch (e) {
      debugPrint('Native MethodChannel launchUpiChooser error: $e');
    }

    // 2. Fallback attempt via url_launcher
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) return true;
      }

      final launchedDirectly = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedDirectly) return true;
    } catch (e) {
      debugPrint('Error launching UPI URI via url_launcher: $e');
    }

    throw Exception(
      'No UPI app (GPay, PhonePe, Paytm, BHIM) found on this device.',
    );
  }

  /// Shows the "Pay" bottom sheet with payment method options:
  /// - 💳 UPI (GPay, PhonePe, Paytm)
  /// - 🏦 Bank Transfer
  /// - 💵 Cash
  /// - Cancel
  static void showPaymentMethodBottomSheet({
    required BuildContext context,
    required String name,
    required double amount,
    required String upiId,
    VoidCallback? onSettled,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _PaymentMethodBottomSheet(
          parentContext: context,
          name: name,
          amount: amount,
          initialUpiId: upiId,
          onSettled: onSettled,
        );
      },
    );
  }

  /// Shows the "Mark Paid" bottom sheet for offline / external settlements:
  /// - 💵 Cash Payment
  /// - 📱 Paid via Other UPI App
  /// - 🏦 Bank Transfer
  /// - ⚡ Mark as Settled Directly
  static void showMarkPaidBottomSheet({
    required BuildContext context,
    required String name,
    required double amount,
    VoidCallback? onSettled,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.xxl,
            AppSizes.m,
            AppSizes.xxl,
            AppSizes.l,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title: Mark Paid to Rahul
              Text(
                'Mark Paid to $name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'How was this ₹${amount.toStringAsFixed(0)} payment completed?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),

              // 1. Cash Payment
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '💵',
                title: 'Cash Payment',
                subtitle: 'Paid in person with physical cash',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notifySettled(
                    context,
                    name,
                    amount,
                    'in cash 💵',
                    onSettled,
                  );
                },
              ),
              const SizedBox(height: AppSizes.m),

              // 2. Paid via other UPI app
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '📱',
                title: 'Paid via Other UPI App',
                subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notifySettled(
                    context,
                    name,
                    amount,
                    'via UPI 📱',
                    onSettled,
                  );
                },
              ),
              const SizedBox(height: AppSizes.m),

              // 3. Bank Transfer
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '🏦',
                title: 'Bank Transfer',
                subtitle: 'NEFT, IMPS or direct transfer',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notifySettled(
                    context,
                    name,
                    amount,
                    'via Bank Transfer 🏦',
                    onSettled,
                  );
                },
              ),
              const SizedBox(height: AppSizes.m),

              // 4. Mark as Settled Directly
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '⚡',
                title: 'Payment Outside Splitiko',
                subtitle: 'Mark balance settled immediately',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notifySettled(context, name, amount, '✓', onSettled);
                },
              ),
              const SizedBox(height: AppSizes.l),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _notifySettled(
    BuildContext context,
    String name,
    double amount,
    String method,
    VoidCallback? onSettled,
  ) {
    if (onSettled != null) {
      onSettled();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Payment of ₹${amount.toStringAsFixed(0)} to $name marked as settled $method! 🎉',
        ),
        backgroundColor: AppColors.expensePositive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Widget _buildPaymentOptionTile({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color:
                  isDarkMode
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback dialog if UPI app intent cannot be resolved directly
  static void _showUpiFallbackDialog({
    required BuildContext context,
    required String name,
    required String upiId,
    required double amount,
    VoidCallback? onSettled,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.xxl),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'UPI Payment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open any UPI app and transfer ₹${amount.toStringAsFixed(0)} to:',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // UPI ID container with copy button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDarkMode
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recipient UPI ID',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDarkMode
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            upiId,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: upiId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied $upiId to clipboard!'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _notifySettled(context, name, amount, '✓', onSettled);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Mark as Settled ✓',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bank transfer details bottom sheet with editable fields
  static void _showBankTransferDialog({
    required BuildContext context,
    required String name,
    required double amount,
    VoidCallback? onSettled,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) {
        return _EditableBankTransferDialog(
          parentContext: context,
          name: name,
          amount: amount,
          onSettled: onSettled,
        );
      },
    );
  }

  static void _showPaymentConfirmationDialog({
    required BuildContext context,
    required String name,
    required double amount,
    required String upiId,
    VoidCallback? onSettled,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.xxl,
            AppSizes.m,
            AppSizes.xxl,
            AppSizes.l,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
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
                    color:
                        isDarkMode
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '💸 Did the payment go through?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '₹${amount.toStringAsFixed(0)} to $name via $upiId',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),

              // Yes — mark settled
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _notifySettled(
                    context,
                    name,
                    amount,
                    'via UPI 📱',
                    onSettled,
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'Yes, Payment Successful ✓',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // No — retry or cancel
              OutlinedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text(
                  'No, Payment Failed',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

class _PaymentMethodBottomSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String name;
  final double amount;
  final String initialUpiId;
  final VoidCallback? onSettled;

  const _PaymentMethodBottomSheet({
    required this.parentContext,
    required this.name,
    required this.amount,
    required this.initialUpiId,
    this.onSettled,
  });

  @override
  State<_PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<_PaymentMethodBottomSheet> {
  late final TextEditingController _upiController;
  bool _isEditingUpi = false;

  @override
  void initState() {
    super.initState();
    final clean = widget.initialUpiId.trim();
    final isDummy =
        clean.isEmpty || clean.contains('@okaxis') || clean == 'splitico@upi';
    _upiController = TextEditingController(text: isDummy ? '' : clean);
    _isEditingUpi = isDummy;
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  void _payWithUpi() async {
    final upiId = _upiController.text.trim();
    if (upiId.isEmpty || !upiId.contains('@')) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid UPI ID for ${widget.name} (e.g. name@oksbi)',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isEditingUpi = true;
      });
      return;
    }

    Navigator.of(context).pop();

    bool launched = false;
    try {
      await UpiPaymentService.pay(
        upiId: upiId,
        name: widget.name,
        amount: widget.amount,
      );
      launched = true;
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!widget.parentContext.mounted) return;

    if (launched) {
      // GPay/UPI launched — ask if payment completed since we can't read the result
      if (launched) {
        UpiPaymentService._showPaymentConfirmationDialog(
          context: widget.parentContext,
          name: widget.name,
          amount: widget.amount,
          upiId: upiId,
          onSettled: widget.onSettled,
        );
      } else {
        UpiPaymentService._showUpiFallbackDialog(
          context: widget.parentContext,
          name: widget.name,
          upiId: upiId,
          amount: widget.amount,
          onSettled: widget.onSettled,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xxl,
        AppSizes.m,
        AppSizes.xxl,
        AppSizes.l + bottomInset,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title: Pay Rahul ₹500
            Text(
              'Pay ${widget.name} ₹${widget.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              'Choose payment method',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.l),

            // Editable Recipient UPI ID Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECIPIENT UPI ID',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isDarkMode
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditingUpi = !_isEditingUpi;
                          });
                        },
                        child: Text(
                          _isEditingUpi ? 'Done' : 'Edit',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_isEditingUpi)
                    TextField(
                      controller: _upiController,
                      autofocus: _upiController.text.isEmpty,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText:
                            "Enter ${widget.name}'s UPI ID (e.g. 9876543210@paytm)",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color:
                              isDarkMode
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    Text(
                      _upiController.text.isNotEmpty
                          ? _upiController.text
                          : 'No UPI ID set (tap Edit to add)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            _upiController.text.isNotEmpty
                                ? theme.colorScheme.onSurface
                                : Colors.orange.shade400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.m),

            // 1. UPI Payment Option (Triggers Android's Native App Chooser)
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '💳',
              title: 'Pay via UPI',
              subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
              isDarkMode: isDarkMode,
              onTap: _payWithUpi,
            ),
            const SizedBox(height: AppSizes.m),

            // 2. Bank Transfer Option
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '🏦',
              title: 'Bank Transfer',
              subtitle: 'Direct IMPS / NEFT transfer',
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).pop();
                UpiPaymentService._showBankTransferDialog(
                  context: widget.parentContext,
                  name: widget.name,
                  amount: widget.amount,
                  onSettled: widget.onSettled,
                );
              },
            ),
            const SizedBox(height: AppSizes.m),

            // 3. Cash Option
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '💵',
              title: 'Cash',
              subtitle: 'Settle in person with physical cash',
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).pop();
                UpiPaymentService._notifySettled(
                  widget.parentContext,
                  widget.name,
                  widget.amount,
                  'in cash 💵',
                  widget.onSettled,
                );
              },
            ),
            const SizedBox(height: AppSizes.l),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor:
                    isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableBankTransferDialog extends StatefulWidget {
  final BuildContext parentContext;
  final String name;
  final double amount;
  final VoidCallback? onSettled;

  const _EditableBankTransferDialog({
    required this.parentContext,
    required this.name,
    required this.amount,
    this.onSettled,
  });

  @override
  State<_EditableBankTransferDialog> createState() =>
      _EditableBankTransferDialogState();
}

class _EditableBankTransferDialogState
    extends State<_EditableBankTransferDialog> {
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  late final TextEditingController _bankNameController;

  @override
  void initState() {
    super.initState();
    _accountNameController = TextEditingController(text: widget.name);
    _accountNumberController = TextEditingController(text: '919876543210');
    _ifscController = TextEditingController(text: 'HDFC0001234');
    _bankNameController = TextEditingController(text: 'HDFC Bank');
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _copyField(String label, String value) {
    if (value.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: value.trim()));
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyAllDetails() {
    final text =
        '''
Account Holder: ${_accountNameController.text.trim()}
Account Number: ${_accountNumberController.text.trim()}
IFSC Code: ${_ifscController.text.trim().toUpperCase()}
Bank: ${_bankNameController.text.trim()}
Amount: ₹${widget.amount.toStringAsFixed(2)}
'''.trim();

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      const SnackBar(
        content: Text('All bank details copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xxl,
        AppSizes.m,
        AppSizes.xxl,
        AppSizes.l + bottomInset,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Transfer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Edit & copy recipient bank details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isDarkMode
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDarkMode ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${widget.amount.toStringAsFixed(widget.amount % 1 == 0 ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.l),

            // 1. Account Holder Name
            _buildEditableField(
              label: 'ACCOUNT HOLDER NAME',
              controller: _accountNameController,
              icon: Icons.person_outline_rounded,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),

            // 2. Account Number
            _buildEditableField(
              label: 'ACCOUNT NUMBER',
              controller: _accountNumberController,
              icon: Icons.credit_card_rounded,
              isDarkMode: isDarkMode,
              keyboardType: TextInputType.number,
              showCopy: true,
              onCopy:
                  () => _copyField(
                    'Account number',
                    _accountNumberController.text,
                  ),
            ),
            const SizedBox(height: 12),

            // 3. IFSC Code
            _buildEditableField(
              label: 'IFSC CODE',
              controller: _ifscController,
              icon: Icons.pin_outlined,
              isDarkMode: isDarkMode,
              textCapitalization: TextCapitalization.characters,
              showCopy: true,
              onCopy: () => _copyField('IFSC code', _ifscController.text),
            ),
            const SizedBox(height: 12),

            // 4. Bank Name
            _buildEditableField(
              label: 'BANK NAME',
              controller: _bankNameController,
              icon: Icons.account_balance_outlined,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: AppSizes.l),

            // Copy All Details Button
            ElevatedButton.icon(
              onPressed: _copyAllDetails,
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text(
                'Copy All Bank Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Mark as Settled Button
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                UpiPaymentService._notifySettled(
                  widget.parentContext,
                  widget.name,
                  widget.amount,
                  'via Bank Transfer 🏦',
                  widget.onSettled,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Mark as Settled ✓',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool showCopy = false,
    VoidCallback? onCopy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color:
                isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDarkMode
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (showCopy && onCopy != null)
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: AppColors.primary,
                  tooltip: 'Copy',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
