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
    return FittedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isAccountCreated
                ? LocaleKeys.not_member.tr()
                : LocaleKeys.question_account.tr(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.tertiary, fontSize: 18),
          ),
          const SizedBox(
            width: 5,
          ),
          GestureDetector(
            onTap: loginRegisterSwitch,
            child: Text(
              isAccountCreated
                  ? LocaleKeys.create_account.tr()
                  : LocaleKeys.sign_account.tr(),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.scrim,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
