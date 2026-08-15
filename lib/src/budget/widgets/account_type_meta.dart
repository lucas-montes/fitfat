import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/account.dart';

IconData accountTypeIcon(AccountType type) => switch (type) {
      AccountType.savings => Icons.savings_outlined,
      AccountType.investment => Icons.trending_up_outlined,
      AccountType.cash => Icons.wallet_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.credit => Icons.credit_card_outlined,
      AccountType.other => Icons.category_outlined,
    };

String accountTypeLabel(AppLocalizations l10n, AccountType type) =>
    switch (type) {
      AccountType.savings => l10n.accountTypeSavings,
      AccountType.investment => l10n.accountTypeInvestment,
      AccountType.cash => l10n.accountTypeCash,
      AccountType.bank => l10n.accountTypeBank,
      AccountType.credit => l10n.accountTypeCredit,
      AccountType.other => l10n.accountTypeOther,
    };
