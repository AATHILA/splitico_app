import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class UpiPaymentService {
  /// Builds a standard NPCI compliant UPI payment URI.
  static Uri buildUri({
    required String upiId,
    required String name,
    required double amount,
    String? note,
  }) {
    final cleanUpiId = upiId.trim();
    final cleanName = name.trim();
    final cleanNote = (note ?? 'Splitico Settlement').trim();
    final formattedAmount = amount.toStringAsFixed(2);

    final urlString =
        'upi://pay?pa=$cleanUpiId&pn=${Uri.encodeComponent(cleanName)}&am=$formattedAmount&cu=INR&tn=${Uri.encodeComponent(cleanNote)}';

    return Uri.parse(urlString);
  }

  /// Attempts to launch the UPI app directly.
  static Future<bool> pay({
    required String upiId,
    required String name,
    required double amount,
    String? note,
  }) async {
    final uri = buildUri(
      upiId: upiId,
      name: name,
      amount: amount,
      note: note,
    );

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }

      // Fallback attempt: on some devices canLaunchUrl reports false due to OEM restrictions,
      // but launchUrl still succeeds in opening the system intent chooser.
      final launchedDirectly = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedDirectly) return true;
    } catch (e) {
      debugPrint('Error launching UPI URI: $e');
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
              color: isDarkMode
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
                    color: isDarkMode
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title: Pay Rahul ₹500
              Text(
                'Pay $name ₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Subtitle: Choose payment method
              Text(
                'Choose payment method',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),

              // 1. UPI Option
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '💳',
                title: 'UPI',
                subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                isDarkMode: isDarkMode,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await pay(
                      upiId: upiId,
                      name: name,
                      amount: amount,
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                    if (context.mounted) {
                      _showUpiFallbackDialog(
                        context: context,
                        name: name,
                        upiId: upiId,
                        amount: amount,
                        onSettled: onSettled,
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSizes.m),

              // 2. Bank Transfer Option
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '🏦',
                title: 'Bank Transfer',
                subtitle: 'Direct IMPS / NEFT transfer',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showBankTransferDialog(
                    context: context,
                    name: name,
                    amount: amount,
                    onSettled: onSettled,
                  );
                },
              ),
              const SizedBox(height: AppSizes.m),

              // 3. Cash Option
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '💵',
                title: 'Cash',
                subtitle: 'Settle in person with physical cash',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _notifySettled(context, name, amount, 'in cash 💵', onSettled);
                },
              ),
              const SizedBox(height: AppSizes.l),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
              color: isDarkMode
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
                    color: isDarkMode
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
                  color: isDarkMode
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
                  _notifySettled(context, name, amount, 'in cash 💵', onSettled);
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
                  _notifySettled(context, name, amount, 'via UPI 📱', onSettled);
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
                  _notifySettled(context, name, amount, 'via Bank Transfer 🏦', onSettled);
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
                  foregroundColor: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
            color: isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode
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
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode
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
              color: isDarkMode
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
                  color: isDarkMode
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
                  color: isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode
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
                              color: isDarkMode
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

  /// Bank transfer details bottom sheet
  static void _showBankTransferDialog({
    required BuildContext context,
    required String name,
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
              color: isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bank Transfer to $name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Amount to transfer: ₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  'Account Number: 919876543210\nIFSC Code: HDFC0001234\nAccount Name: $name\nBank: HDFC Bank',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: '919876543210'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account number copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy Account Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _notifySettled(context, name, amount, 'via Bank Transfer 🏦', onSettled);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
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
        );
      },
    );
  }
}