import 'package:flutter_test/flutter_test.dart';
import 'package:splitico/core/services/upi_payment_service.dart';

void main() {
  group('UpiPaymentService', () {
    test('buildUriString generates valid P2P URI without tr by default', () {
      final uriStr = UpiPaymentService.buildUriString(
        upiId: 'john@oksbi',
        name: 'John Doe',
        amount: 250.50,
        note: 'Dinner Settle',
      );

      expect(uriStr, contains('pa=john@oksbi'));
      expect(uriStr, contains('pn=John%20Doe'));
      expect(uriStr, contains('am=250.50'));
      expect(uriStr, contains('cu=INR'));
      expect(uriStr, contains('tn=Dinner%20Settle'));
      expect(uriStr, isNot(contains('&tr=')));
    });

    test('buildUriString includes tr parameter when explicitly provided', () {
      final uriStr = UpiPaymentService.buildUriString(
        upiId: 'john@oksbi',
       name: 'John Doe',
        amount: 100.00,
      
      );

      expect(uriStr, contains('&tr=TXN12345'));
    });
 });
}

