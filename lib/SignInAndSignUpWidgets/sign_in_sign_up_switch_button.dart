import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class SignInSignUpSwitchButton extends StatelessWidget {
  final bool isAccountCreated;
  final void Function() loginRegisterSwitch;

  const SignInSignUpSwitchButton(
      {super.key,
      required this.isAccountCreated,
      required this.loginRegisterSwitch});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            isAccountCreated
                ? LocaleKeys.not_member.tr()
                : LocaleKeys.question_account.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: loginRegisterSwitch,
          child: Text(
            isAccountCreated
                ? LocaleKeys.create_account.tr()
                : LocaleKeys.sign_account.tr(),
          ),
        ),
      ],
    );
  }
}
