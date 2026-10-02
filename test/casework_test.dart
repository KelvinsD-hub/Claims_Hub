import 'package:claims_hub/backend/services/casework.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime daysFromNow(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, 23, 59);
  }

  test('a record with no casework fields reads as unowned and idle', () {
    final work = Casework.of(const {});
    expect(work.hasHandler, isFalse);
    expect(work.hasLawyer, isFalse);
    expect(work.hasNextAction, isFalse);
    expect(work.isOverdue, isFalse);
    expect(work.dueLabel, '');
    expect(work.legalStage, '');
  });

  test('owner and next action are read from the document', () {
    final work = Casework.of({
      'handler_uid': 'u1',
      'handler_name': 'Ada',
      'lawyer_uid': 'u2',
      'lawyer_name': 'Sola',
      'next_action': 'Chase the client',
      'next_action_due': daysFromNow(3),
      'legal_stage': LegalStage.ncaa,
      'amount_recovered': 170000,
    });
    expect(work.handlerName, 'Ada');
    expect(work.lawyerName, 'Sola');
    expect(work.hasNextAction, isTrue);
    expect(work.legalStage, LegalStage.ncaa);
    expect(work.amountRecovered, 170000.0);
  });

  test('the due label counts whole days', () {
    Casework due(int days) =>
        Casework.of({'next_action': 'x', 'next_action_due': daysFromNow(days)});
    expect(due(5).dueLabel, 'Due in 5 days');
    expect(due(1).dueLabel, 'Due tomorrow');
    expect(due(0).dueLabel, 'Due today');
    expect(due(-1).dueLabel, 'Overdue by 1 day');
    expect(due(-4).dueLabel, 'Overdue by 4 days');
  });

  test('something due today is not overdue until the day ends', () {
    expect(
        Casework.of({'next_action': 'x', 'next_action_due': daysFromNow(0)})
            .isOverdue,
        isFalse);
    expect(
        Casework.of({'next_action': 'x', 'next_action_due': daysFromNow(-1)})
            .isOverdue,
        isTrue);
  });

  test('a passed date with no action left is not overdue', () {
    expect(
        Casework.of({'next_action_due': daysFromNow(-3)}).isOverdue, isFalse);
  });

  test('roles', () {
    expect(isLegalRole('Solicitor'), isTrue);
    expect(isLegalRole('Manager'), isTrue);
    expect(isLegalRole('Agent'), isFalse);
    expect(isManagerRole('Super Admin'), isTrue);
    expect(isManagerRole('Solicitor'), isFalse);
  });

  test('legal stages are in the usual order', () {
    expect(LegalStage.all, [
      'Legal review',
      'Final notice sent',
      'NCAA complaint filed',
      'Court proceedings',
    ]);
  });

  test('a client\'s objection to AI is read from the record', () {
    expect(Casework.of({}).aiOptOut, isFalse);
    expect(Casework.of({'ai_opt_out': false}).aiOptOut, isFalse);
    final work = Casework.of({'ai_opt_out': true, 'ai_opt_out_by_name': 'Ada'});
    expect(work.aiOptOut, isTrue);
    expect(work.aiOptOutByName, 'Ada');
  });

  test('a handler name with nobody behind it is not an owner', () {
    final work = Casework.of({'handler_name': 'Claims Assist Limited'});
    expect(work.hasHandler, isFalse);
    expect(work.handlerName, '');
    expect(
        Casework.of({'handler_uid': 'ada', 'handler_name': 'Ada'}).handlerName,
        'Ada');
  });
}
