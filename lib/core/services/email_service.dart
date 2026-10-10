import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Reads SMTP server config directly from .env
  SmtpServer _getSmtpServer() {
    final host = dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
    final port = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
    final username = dotenv.env['SMTP_USER'] ?? '';
    final password = dotenv.env['SMTP_PASS'] ?? '';

    // If host is gmail, we can use the dedicated gmail helper or custom SmtpServer
    if (host.toLowerCase().contains('gmail')) {
      return gmail(username, password);
    }

    return SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: port == 465,
      allowInsecure: false,
    );
  }

  /// Send a generic email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String text,
    String? html,
  }) async {
    final username = dotenv.env['SMTP_USER'] ?? '';
    final senderName = dotenv.env['SMTP_SENDER_NAME'] ?? 'Splitiko';

    if (username.isEmpty) {
      debugPrint('[EmailService] SMTP_USER is not configured in .env');
      return false;
    }

    final message = Message()
      ..from = Address(username, senderName)
      ..recipients.add(to)
      ..subject = subject
      ..text = text;

    if (html != null) {
      message.html = html;
    }

    try {
      final smtpServer = _getSmtpServer();
      final sendReport = await send(message, smtpServer);
      debugPrint('[EmailService] Email sent successfully: $sendReport');
      return true;
    } catch (e) {
      debugPrint('[EmailService] Error sending email: $e');
      return false;
    }
  }

  /// Send branded OTP email with HTML template
  Future<bool> sendOtpEmail({
    required String to,
    required String otp,
    String? name,
  }) async {
    final displayName = name != null && name.trim().isNotEmpty ? name : 'there';
    const subject = 'Your Splitiko Verification Code';

    final text = 'Hello $displayName,\n\nYour 6-digit Splitiko verification code is: $otp\n\nThis code will expire in 10 minutes.\n\nBest regards,\nSplitiko Team';

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 24px; }
    .card { max-width: 480px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }
    .logo { color: #4C49ED; font-size: 24px; font-weight: 800; margin-bottom: 24px; }
    h2 { color: #1E293B; font-size: 20px; margin-top: 0; }
    p { color: #64748B; font-size: 15px; line-height: 1.6; }
    .otp-box { background: #EEF2FF; border: 2px dashed #4C49ED; border-radius: 12px; padding: 16px; text-align: center; margin: 24px 0; }
    .otp-code { font-size: 32px; font-weight: 800; letter-spacing: 6px; color: #4C49ED; font-family: monospace; }
    .footer { font-size: 13px; color: #94A3B8; text-align: center; margin-top: 24px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">Splitiko</div>
    <h2>Verify your email</h2>
    <p>Hi <b>$displayName</b>,</p>
    <p>Thank you for signing up. Please enter the following 6-digit code in the app to complete your verification:</p>
    <div class="otp-box">
      <span class="otp-code">$otp</span>
    </div>
    <p>This verification code is valid for 10 minutes. If you did not request this code, you can safely ignore this email.</p>
    <div class="footer">
      &copy; Splitiko. All rights reserved.
    </div>
  </div>
</body>
</html>
''';

    return await sendEmail(
      to: to,
      subject: subject,
      text: text,
      html: html,
    );
  }
}
