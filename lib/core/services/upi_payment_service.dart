import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../services/payment_reminder_service.dart';
import '../../features/settlement/pages/qr_scanner_page.dart';

class UpiPaymentService {
  /// Builds a standard NPCI compliant P2P UPI payment URI String.
  static String buildUriString({
    required String upiId,
    required String name,
    required double amount,
    String? note,
  }) {
    final cleanUpiId = upiId.trim();
    final cleanName = name.trim();
    final formattedAmount = amount.toStringAsFixed(2);
    final cleanNote = note?.trim() ?? 'Splitico Settlement';

    final uriBuffer = StringBuffer()
      ..write('upi://pay')
      ..write('?pa=$cleanUpiId')
      ..write('&pn=${Uri.encodeComponent(cleanName)}')
      ..write('&am=$formattedAmount')
      ..write('&cu=INR');

    if (cleanNote.isNotEmpty) {
      uriBuffer.write('&tn=${Uri.encodeComponent(cleanNote)}');
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

  /// Primary Pay entry point when clicking "Pay".
  /// Opens the payment hub with all payment options:
  /// - 📷 Scan Receiver's QR Code
  /// - 📲 Show Receiver's QR Code (to scan with UPI app)
  /// - 📱 Pay via UPI Apps Separately (Copy UPI ID & Mark Paid)
  /// - 🏦 Bank Transfer (IMPS / NEFT)
  /// - 💵 Cash Payment
  static void directPay({
    required BuildContext context,
    required String name,
    required double amount,
    required String upiId,
    VoidCallback? onSettled,
  }) {
    _notifySettled(context, name, amount, '✓', onSettled);
  }

  /// Shows the full "Pay" bottom sheet with all payment options
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

  /// Opens the camera QR code scanner to scan receiver's QR code
  static Future<void> openQrScanner({
    required BuildContext context,
    required String name,
    required double amount,
    required String upiId,
    VoidCallback? onSettled,
  }) async {
    final result = await Navigator.of(context).push<UpiQrData>(
      MaterialPageRoute(
        builder: (ctx) => QrScannerPage(
          expectedRecipientName: name,
          expectedAmount: amount,
          expectedUpiId: upiId.isNotEmpty ? upiId : null,
        ),
      ),
    );

    if (result != null && context.mounted) {
      _notifySettled(
        context,
        name,
        amount,
        'via QR Code Scan 📷',
        onSettled,
      );
    }
  }

  /// Shows the receiver's QR code modal for scanning
  static void showQrCodeBottomSheet({
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
        return _ReceiverQrCodeSheet(
          parentContext: context,
          name: name,
          amount: amount,
          upiId: upiId,
          onSettled: onSettled,
        );
      },
    );
  }

  /// Shows the manual UPI payment instructions dialog with copy button
  static void showManualUpiPaymentDialog({
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
        return _ManualUpiSheet(
          parentContext: context,
          name: name,
          amount: amount,
          upiId: upiId,
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
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

              // 2. Paid via UPI App
              _buildPaymentOptionTile(
                context: sheetContext,
                icon: '📱',
                title: 'Paid via UPI App',
                subtitle: 'Google Pay, PhonePe, Paytm, BHIM, CRED',
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
                subtitle: 'NEFT, IMPS or direct net banking transfer',
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
                title: 'Payment Outside Splitico',
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
                  foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
    Widget? trailing,
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
            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
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
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }

  /// Bank transfer details bottom sheet with editable fields
  static void showBankTransferDialog({
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
}

/// The Main Payment Method Bottom Sheet
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
  State<_PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<_PaymentMethodBottomSheet> {
  late final TextEditingController _upiController;
  bool _isEditingUpi = false;

  @override
  void initState() {
    super.initState();
    final clean = widget.initialUpiId.trim();
    final isDummy = clean.isEmpty || clean.contains('@okaxis') || clean == 'splitico@upi';
    _upiController = TextEditingController(text: isDummy ? '' : clean);
    _isEditingUpi = isDummy;
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  String get _effectiveUpiId {
    final upi = _upiController.text.trim();
    return upi.isNotEmpty ? upi : '${widget.name.toLowerCase().replaceAll(' ', '')}@upi';
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
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay ${widget.name}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose how you want to pay & settle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDarkMode ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '₹${widget.amount.toStringAsFixed(widget.amount % 1 == 0 ? 0 : 2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.l),

            // Recipient UPI ID Card with Inline Edit & Copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (_upiController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _upiController.text.trim()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied ${_upiController.text} to clipboard!'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
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
                        hintText: "Enter ${widget.name}'s UPI ID (e.g. name@oksbi)",
                        hintStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
                        color: _upiController.text.isNotEmpty
                            ? theme.colorScheme.onSurface
                            : Colors.orange.shade400,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.l),

            // Option 1: Generate QR Code & Pay 📲
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '📲',
              title: 'Generate QR Code & Pay',
              subtitle: 'Generate UPI QR code to scan with any UPI app',
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).pop();
                UpiPaymentService.showQrCodeBottomSheet(
                  context: widget.parentContext,
                  name: widget.name,
                  amount: widget.amount,
                  upiId: _effectiveUpiId,
                  onSettled: widget.onSettled,
                );
              },
            ),
            const SizedBox(height: AppSizes.m),

            // Option 2: Bank Transfer 🏦
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '🏦',
              title: 'Bank Transfer',
              subtitle: 'Direct IMPS / NEFT transfer details',
              isDarkMode: isDarkMode,
              onTap: () {
                Navigator.of(context).pop();
                UpiPaymentService.showBankTransferDialog(
                  context: widget.parentContext,
                  name: widget.name,
                  amount: widget.amount,
                  onSettled: widget.onSettled,
                );
              },
            ),
            const SizedBox(height: AppSizes.m),

            // Option 3: Cash Pay 💵
            UpiPaymentService._buildPaymentOptionTile(
              context: context,
              icon: '💵',
              title: 'Cash Pay',
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
                foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

/// Receiver's QR Code Bottom Sheet (Generate QR Code & Pay)
class _ReceiverQrCodeSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String name;
  final double amount;
  final String upiId;
  final VoidCallback? onSettled;

  const _ReceiverQrCodeSheet({
    required this.parentContext,
    required this.name,
    required this.amount,
    required this.upiId,
    this.onSettled,
  });

  @override
  State<_ReceiverQrCodeSheet> createState() => _ReceiverQrCodeSheetState();
}

class _ReceiverQrCodeSheetState extends State<_ReceiverQrCodeSheet> {
  final GlobalKey _qrCardKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  Future<Uint8List?> _captureQrPng() async {
    try {
      final boundary = _qrCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR: $e');
      return null;
    }
  }

  Future<void> _openUpiApp() async {
    final upiPayload = UpiPaymentService.buildUriString(
      upiId: widget.upiId,
      name: widget.name,
      amount: widget.amount,
      note: 'Splitico Settlement',
    );
    final uri = Uri.parse(upiPayload);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: widget.upiId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copied ${widget.upiId} to clipboard. Open PhonePe, Paytm, GPay, or super.money to pay!',
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching UPI: $e');
      Clipboard.setData(ClipboardData(text: widget.upiId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${widget.upiId} to clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveQrCode() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final bytes = await _captureQrPng();
      if (bytes == null) {
        throw Exception('Could not render QR code image.');
      }

      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission is required to save QR Code to gallery.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final cleanName = widget.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filename = 'Splitico_QR_${cleanName}_${widget.amount.toInt()}';
      await Gal.putImageBytes(bytes, name: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('QR Code saved to your gallery. 📸'),
              ],
            ),
            backgroundColor: AppColors.expensePositive,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save QR Code: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareQrCode() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final bytes = await _captureQrPng();
      if (bytes == null) {
        throw Exception('Could not render QR code image.');
      }

      final tempDir = await getTemporaryDirectory();
      final cleanName = widget.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filename = 'Splitico_QR_${cleanName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      final upiPayload = UpiPaymentService.buildUriString(
        upiId: widget.upiId,
        name: widget.name,
        amount: widget.amount,
        note: 'Splitico Settlement',
      );

      final shareText = 'Pay ₹${widget.amount.toStringAsFixed(widget.amount % 1 == 0 ? 0 : 2)} to ${widget.name} (${widget.upiId}) via UPI QR Code (PhonePe, Paytm, Google Pay, super.money, CRED):\n$upiPayload';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText,
          subject: 'Splitico Payment QR - ${widget.name}',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share QR Code: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final upiPayload = UpiPaymentService.buildUriString(
      upiId: widget.upiId,
      name: widget.name,
      amount: widget.amount,
      note: 'Splitico Settlement',
    );

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
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Generate QR Code & Pay',
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
              'Scan or share with PhonePe, Paytm, GPay, super.money or any UPI app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            // RepaintBoundary QR Code Card for pixel-perfect save & share
            Center(
              child: RepaintBoundary(
                key: _qrCardKey,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Splitico Header Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Splitico UPI Payment',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // QR Code Widget
                      QrImageView(
                        data: upiPayload,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Payee & Amount Info
                      Text(
                        '₹${widget.amount.toStringAsFixed(widget.amount % 1 == 0 ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paying ${widget.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.upiId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 1. Pay via UPI App (Direct Intent to PhonePe, GPay, Paytm, super.money, CRED)
            ElevatedButton.icon(
              onPressed: _openUpiApp,
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: Text(
                'Pay ₹${widget.amount.toStringAsFixed(0)} via UPI App',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 2. Save QR Code & Share & Pay Buttons Row
            Row(
              children: [
                // Save QR Code
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _saveQrCode,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save QR',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Share & Pay
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSharing ? null : _shareQrCode,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      _isSharing ? 'Opening...' : 'Share & Pay',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. Mark as Paid button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                UpiPaymentService._notifySettled(
                  widget.parentContext,
                  widget.name,
                  widget.amount,
                  'via QR Code 📲',
                  widget.onSettled,
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'Mark as Paid ✓',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expensePositive,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 4. Copy UPI ID Button
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.upiId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied ${widget.upiId} to clipboard!'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: Text(
                'Copy ${widget.upiId}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual UPI Sheet (Copy UPI ID & open external UPI app)
class _ManualUpiSheet extends StatelessWidget {
  final BuildContext parentContext;
  final String name;
  final double amount;
  final String upiId;
  final VoidCallback? onSettled;

  const _ManualUpiSheet({
    required this.parentContext,
    required this.name,
    required this.amount,
    required this.upiId,
    this.onSettled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Pay via UPI App',
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
              'Copy UPI ID and complete transfer in any UPI app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: Copy UPI ID card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          upiId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
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
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // How to pay steps
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildStepRow(
                    number: '1',
                    text: 'Copy the UPI ID above',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow(
                    number: '2',
                    text: 'Open your UPI app (GPay, PhonePe, Paytm, etc.)',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow(
                    number: '3',
                    text: 'Paste the UPI ID and send ₹${amount.toStringAsFixed(0)}',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _buildStepRow(
                    number: '4',
                    text: 'Come back here and tap "Mark as Paid"',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mark Paid Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                UpiPaymentService._notifySettled(
                  parentContext,
                  name,
                  amount,
                  'via UPI 📱',
                  onSettled,
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text(
                'I Have Paid via UPI ✓',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expensePositive,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Track & Remind Later Button
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await PaymentReminderService.trackPayment(
                  recipientName: name,
                  amount: amount,
                  upiId: upiId,
                );
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Payment tracked! We will notify you to confirm ⏰ (up to 2 times)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.access_time_rounded, size: 18),
              label: const Text(
                'Remind Me Later ⏰ (Track Payment)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String text,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bank Transfer Dialog with copy functionality
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
  State<_EditableBankTransferDialog> createState() => _EditableBankTransferDialogState();
}

class _EditableBankTransferDialogState extends State<_EditableBankTransferDialog> {
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
    final text = '''
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
                  color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
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
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
              onCopy: () => _copyField(
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
            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
