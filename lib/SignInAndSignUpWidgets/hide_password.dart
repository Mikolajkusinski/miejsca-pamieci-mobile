import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:memo_places_mobile/translations/locale_keys.g.dart';

class HidePassword extends StatelessWidget {
  final bool isPasswordHidden;
  final void Function() onHiddenChange;

  const HidePassword(
      {super.key,
      required this.isPasswordHidden,
      required this.onHiddenChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onHiddenChange,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Icon(
            isPasswordHidden ? Icons.lock_open : Icons.lock,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            isPasswordHidden
                ? LocaleKeys.show_pass.tr()
                : LocaleKeys.hide_pass.tr(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          )
        ]),
      ),
    );
  }
}
