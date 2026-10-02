import 'package:claims_hub/backend/services/demand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ready = <String, dynamic>{
    'full_name': 'Tunde Client',
    'airline_name': 'Air Peace',
    'flight_number': 'P47120',
    'flight_date': '2026-09-01',
    'departure': 'Lagos',
    'destination': 'Abuja',
    'signature': 'iVBORw0KGgo',
    'claims_amount': '₦21,250',
    'pnr_number': 'ABC123',
    'duration_of_delay': '7 hours',
  };

  test('a complete claim is ready', () {
    final r = demandReadiness(ready);
    expect(r.ready, isTrue);
    expect(r.warnings, isEmpty);
  });

  test('an empty claim lists everything the letter needs', () {
    final r = demandReadiness(const {});
    expect(r.ready, isFalse);
    expect(r.blockers.length, 6);
  });

  test('a missing amount is a warning, not a bar', () {
    final r = demandReadiness({...ready, 'claims_amount': ' '});
    expect(r.ready, isTrue);
    expect(r.warnings.length, 1);
  });

  test('half a route is no route', () {
    expect(demandReadiness({...ready, 'destination': ''}).ready, isFalse);
  });

  test('one plain address passes, anything else does not', () {
    expect(isEmailAddress(' legal@flyairpeace.com '), isTrue);
    expect(isEmailAddress('a@b.com, c@d.com'), isFalse);
    expect(isEmailAddress('Legal <legal@air.com>'), isFalse);
    expect(isEmailAddress(''), isFalse);
  });

  test('the airline\'s address is found from the directory', () {
    const directory = [
      (name: 'Arik Air', email: 'legal@arikair.com'),
      (name: 'Air Peace Limited', email: 'legal@flyairpeace.com'),
      (name: 'Broken', email: 'not an address'),
    ];
    expect(
        suggestedAirlineEmail('Air Peace', directory), 'legal@flyairpeace.com');
    expect(suggestedAirlineEmail('arik air', directory), 'legal@arikair.com');
    expect(suggestedAirlineEmail('Ibom Air', directory), '');
    expect(suggestedAirlineEmail('Broken', directory), '');
    expect(suggestedAirlineEmail('', directory), '');
  });
}
