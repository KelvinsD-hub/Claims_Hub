import 'package:claims_hub/backend/services/info_requests.dart';
import 'package:claims_hub/backend/services/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a bare claim from the website is missing everything it was not given',
      () {
    final missing = missingInfoItems(
      RecordKind.claim,
      {
        'flight_number': 'P47120',
        'flight_date': '2026-09-30',
        'claims_reason': 'Flight delay',
        'address': '1 Allen Avenue, Ikeja, Lagos',
      },
      lead: {'phone': '+2348000000000'},
    );
    expect(missing, containsAll(['booking_reference', 'fare', 'date_of_birth',
        'nin', 'passport', 'bvn', 'bank_details', 'id_document']));
    expect(missing, isNot(contains('flight_number')));
    expect(missing, isNot(contains('address')));
    expect(missing, isNot(contains('phone')));
  });

  test('a passport is only asked for when there is no NIN', () {
    final withNin = missingInfoItems(RecordKind.claim, {'NIN': 'iv:x'});
    expect(withNin, isNot(contains('passport')));
    expect(withNin, isNot(contains('nin')));
  });

  test('baggage claims are not asked for the ticket price', () {
    final missing = missingInfoItems(
        RecordKind.claim, {'claims_reason': 'Baggage claim'});
    expect(missing, isNot(contains('fare')));
  });

  test('a lead reads its own booking reference and phone', () {
    final missing = missingInfoItems(RecordKind.lead, {
      'booking_reference': 'ABC123',
      'phone': '+2348000000000',
      'fare_paid': 85000,
      'attached_document': ['x'],
    });
    expect(missing, isNot(contains('booking_reference')));
    expect(missing, isNot(contains('phone')));
    expect(missing, isNot(contains('fare')));
    expect(missing, isNot(contains('id_document')));
  });
}
