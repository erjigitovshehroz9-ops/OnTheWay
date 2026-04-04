import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

/// Rol almashtirish tasdiq oynasi — joriy yorug‘/qorong‘i temaga mos.
Future<bool?> showRoleSwitchConfirmDialog({
  required BuildContext context,
  required String title,
  required String contentLine,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return AlertDialog(
        backgroundColor: t.dialogBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          contentLine,
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: t.textSecondary,
            ),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: t.buttonPrimaryBg,
              foregroundColor: t.buttonPrimaryText,
            ),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      );
    },
  );
}
