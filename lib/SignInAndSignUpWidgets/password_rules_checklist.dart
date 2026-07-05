import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/theme/app_colors.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

/// The sign-up password policy, split into individually checkable rules.
/// All five together are equivalent to the legacy validation regex
/// `^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*\W)(?!.* ).{8,}$`.
class PasswordRules {
  final String password;

  const PasswordRules(this.password);

  bool get length => password.length >= 8 && !password.contains(' ');
  bool get upper => password.contains(RegExp(r'[A-Z]'));
  bool get lower => password.contains(RegExp(r'[a-z]'));
  bool get digit => password.contains(RegExp(r'[0-9]'));
  bool get symbol => password.contains(RegExp(r'\W'));

  bool get allMet => length && upper && lower && digit && symbol;
}

/// Live checklist under the password field so users see *which* rule fails.
class PasswordRulesChecklist extends StatelessWidget {
  final String password;

  const PasswordRulesChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules(password);
    final entries = <(bool, String)>[
      (rules.length, LocaleKeys.pass_rule_length.tr()),
      (rules.upper, LocaleKeys.pass_rule_upper.tr()),
      (rules.lower, LocaleKeys.pass_rule_lower.tr()),
      (rules.digit, LocaleKeys.pass_rule_digit.tr()),
      (rules.symbol, LocaleKeys.pass_rule_symbol.tr()),
    ];
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (met, label) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  met ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: met ? AppColors.success : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: textStyle.copyWith(
                        color: met
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant)),
              ],
            ),
          ),
      ],
    );
  }
}
