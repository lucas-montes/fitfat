import 'package:flutter_test/flutter_test.dart';
import 'package:fitfat/src/budget/models/account.dart';

void main() {
  test('a securities account reads as one, not as "other"', () {
    expect(AccountType.fromName('securities'), AccountType.securities);
  });

  test('an old type still reads as itself until the pull renames it', () {
    expect(AccountType.fromName('bank'), AccountType.bank);
    expect(AccountType.fromName('investment'), AccountType.investment);
    expect(AccountType.fromName('nonsense'), AccountType.other);
  });
}
