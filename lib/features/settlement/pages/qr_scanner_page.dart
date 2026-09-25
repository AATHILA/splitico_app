import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

/// Model representing parsed UPI payment data from a QR code.
class UpiQrData {
  final String rawValue;
  final String? upiId;
  final String? payeeName;
  final double? amount;
  final String? note;
  final String? transactionRef;

  UpiQrData({
    required this.rawValue,
    this.upiId,
    this.payeeName,
    this.amount,
    this.note,
    this.transactionRef,
  });

  bool get isUpi => upiId != null && upiId!.isNotEmpty;

  static UpiQrData parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toLowerCase().startsWith('upi://pay')) {
      try {
        final uri = Uri.parse(trimmed);
        final pa = uri.queryParameters['pa'];
        final pn = uri.queryParameters['pn'];
        final amStr = uri.queryParameters['am'];
        final tn = uri.queryParameters['tn'];
        final tr = uri.queryParameters['tr'];
        double? am;
        if (amStr != null) {
          am = double.tryParse(amStr);
        }
        return UpiQrData(
          rawValue: trimmed,
          upiId: pa,
          payeeName: pn != null ? Uri.decodeComponent(pn) : null,
          amount: am,
          note: tn != null ? Uri.decodeComponent(tn) : null,
          transactionRef: tr,
        );
      } catch (_) {}
    }

    // Check if it's directly a UPI ID (e.g., name@upi)
    if (trimmed.contains('@') && !trimmed.contains(' ') && !trimmed.startsWith('http')) {
      return UpiQrData(
        rawValue: trimmed,
        upiId: trimmed,
      );
    }

    return UpiQrData(rawValue: trimmed);
  }

  String buildUpiUriString({String? fallbackName, double? fallbackAmount}) {
    if (rawValue.toLowerCase().startsWith('upi://pay')) {
      // If rawValue has no amount or fallback is specified
      if ((amount == null || amount! <= 0) && fallbackAmount != null && fallbackAmount > 0) {
        final uri = Uri.parse(rawValue);
        final params = Map<String, String>.from(uri.queryParameters);
        params['am'] = fallbackAmount.toStringAsFixed(2);
        params['cu'] = params['cu'] ?? 'INR';
        if (!params.containsKey('pn') && fallbackName != null) {
          params['pn'] = fallbackName;
        }
        return uri.replace(queryParameters: params).toString();
      }
      return rawValue;
    }

    final cleanUpi = (upiId ?? rawValue).trim();
    final cleanName = (payeeName ?? fallbackName ?? 'Recipient').trim();
    final effectiveAmount = amount ?? fallbackAmount ?? 0.0;
    final formattedAmount = effectiveAmount > 0 ? effectiveAmount.toStringAsFixed(2) : '';

    final uriBuffer = StringBuffer()
      ..write('upi://pay')
      ..write('?pa=$cleanUpi')
      ..write('&pn=${Uri.encodeComponent(cleanName)}');

    if (formattedAmount.isNotEmpty) {
      uriBuffer.write('&am=$formattedAmount');
    }
    uriBuffer.write('&cu=INR');

    return uriBuffer.toString();
  }
}

class QrScannerPage extends StatefulWidget {
  final String? expectedRecipientName;
  final double? expectedAmount;
  final String? expectedUpiId;
  final Function(UpiQrData qrData)? onQrScanned;

  const QrScannerPage({
    super.key,
    this.expectedRecipientName,
    this.expectedAmount,
    this.expectedUpiId,
    this.onQrScanned,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  late final AnimationController _animController;
  late final Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();
    final qrData = UpiQrData.parse(raw);
    _showScannedResultDialog(qrData);
  }



  void _showScannedResultDialog(UpiQrData qrData) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final displayUpi = qrData.upiId ?? widget.expectedUpiId ?? qrData.rawValue;
    final displayName = qrData.payeeName ?? widget.expectedRecipientName ?? 'Recipient';
    final displayAmount = qrData.amount ?? widget.expectedAmount;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'QR Code Scanned!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify payment details and mark as settled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),

              // Info card
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
                  children: [
                    if (displayAmount != null && displayAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '₹${displayAmount.toStringAsFixed(displayAmount % 1 == 0 ? 0 : 2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payee Name',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UPI ID',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            displayUpi,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 1. Primary Action: Mark as Settled Directly
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  if (widget.onQrScanned != null) {
                    widget.onQrScanned!(qrData);
                  }
                  Navigator.of(context).pop(qrData);
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  displayAmount != null
                      ? 'Mark ₹${displayAmount.toStringAsFixed(0)} as Settled ✓'
                      : 'Mark as Settled ✓',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Copy UPI ID & Scan Again Row
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: displayUpi));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied $displayUpi to clipboard!'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy UPI ID'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        setState(() {
                          _isProcessing = false;
                        });
                      },
                      child: Text(
                        'Scan Again',
                        style: TextStyle(
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanBoxSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanBoxSize,
                    height: scanBoxSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Viewfinder Corners and Animated Scan Line
          Center(
            child: SizedBox(
              width: scanBoxSize,
              height: scanBoxSize,
              child: Stack(
                children: [
                  // Corner borders
                  CustomPaint(
                    size: Size(scanBoxSize, scanBoxSize),
                    painter: _ViewfinderPainter(
                      color: AppColors.primary,
                      cornerLength: 28,
                      strokeWidth: 4,
                      borderRadius: 24,
                    ),
                  ),

                  // Animated Scanning Line
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanLineAnimation.value * (scanBoxSize - 20) + 10,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.0),
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Top Header & Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    widget.expectedRecipientName != null
                        ? 'Scan ${widget.expectedRecipientName}\'s QR'
                        : 'Scan QR Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      // Torch toggle
                      IconButton(
                        onPressed: () => _controller.toggleTorch(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Switch camera
                      IconButton(
                        onPressed: () => _controller.switchCamera(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cameraswitch_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Instruction
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.expectedAmount != null
                          ? 'Point camera at receiver\'s UPI QR code to pay & settle ₹${widget.expectedAmount!.toStringAsFixed(0)}'
                          : 'Point camera at any UPI or payment QR code to pay & settle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  _ViewfinderPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = borderRadius;
    final cl = cornerLength;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cl)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(cl, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(w - cl, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, cl);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, h - cl)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(cl, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(w - cl, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - cl);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
