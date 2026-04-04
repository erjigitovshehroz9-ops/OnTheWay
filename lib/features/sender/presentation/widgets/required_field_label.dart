import 'package:flutter/material.dart';

/// Majburiy maydon uchun label + qizil yulduzcha.
class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge?.color;
    return Text.rich(
      TextSpan(
        style: Theme.of(context).inputDecorationTheme.labelStyle ??
            TextStyle(color: base),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
