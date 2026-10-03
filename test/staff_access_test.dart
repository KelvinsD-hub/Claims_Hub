import 'package:claims_hub/backend/services/staff_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 3, 10, 0);

  test('approved staff stay signed in', () {
    expect(
        signInOutcome(
            hasDoc: true,
            approved: true,
            createdAt: now.subtract(const Duration(days: 90)),
            now: now),
        SignInOutcome.allow);
  });

  test('a stranger who just made an account has it removed', () {
    expect(
        signInOutcome(
            hasDoc: false,
            approved: false,
            createdAt: now.subtract(const Duration(seconds: 5)),
            now: now),
        SignInOutcome.removeNewAccount);
  });

  test('an older account without access is only signed out', () {
    expect(
        signInOutcome(
            hasDoc: true,
            approved: false,
            createdAt: now.subtract(const Duration(days: 30)),
            now: now),
        SignInOutcome.signOut);
  });

  test('the WhatsApp link carries the number and the message', () {
    final link = whatsAppLink('Join: https://x.y/?invite=a&b',
        phone: '+234 803 000 1111');
    expect(link, startsWith('https://wa.me/2348030001111?text='));
    expect(Uri.parse(link).queryParameters['text'],
        'Join: https://x.y/?invite=a&b');
  });
}
