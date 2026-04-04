import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';

const int _kComplaintMaxLen = 1200;
const Color _kFeedbackSendButtonColor = Color(0xFF003A90);

ButtonStyle _feedbackSendButtonStyle() => FilledButton.styleFrom(
      backgroundColor: _kFeedbackSendButtonColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: _kFeedbackSendButtonColor.withValues(alpha: 0.38),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
    );

/// Shikoyat: erkin matn. Qaytish: tozalangan matn yoki `null`.
Future<String?> showComplaintFeedbackSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _ComplaintFeedbackSheet(l10n: l10n),
  );
}

/// Maqtov: yulduzlar yoki smayl. `category` — `praise:star:N` yoki `praise:emoji:key`.
Future<String?> showPraiseFeedbackSheet(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _PraiseFeedbackSheet(l10n: l10n),
  );
}

class _ComplaintFeedbackSheet extends StatefulWidget {
  const _ComplaintFeedbackSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ComplaintFeedbackSheet> createState() => _ComplaintFeedbackSheetState();
}

class _ComplaintFeedbackSheetState extends State<_ComplaintFeedbackSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    final clipped =
        t.length > _kComplaintMaxLen ? t.substring(0, _kComplaintMaxLen) : t;
    Navigator.of(context).pop(clipped);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.feedbackComplaintTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              maxLength: _kComplaintMaxLen,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.feedbackComplaintHint,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _ctrl.text.trim().isNotEmpty ? _submit : null,
              style: _feedbackSendButtonStyle(),
              child: Text(l10n.feedbackSend),
            ),
          ],
        ),
      ),
    );
  }
}

/// (kalit, emoji)
const List<(String, String)> _praiseEmojiKeys = [
  ('sad', '😕'),
  ('neutral', '😐'),
  ('ok', '🙂'),
  ('happy', '😄'),
  ('wow', '🤩'),
];

class _PraiseFeedbackSheet extends StatefulWidget {
  const _PraiseFeedbackSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_PraiseFeedbackSheet> createState() => _PraiseFeedbackSheetState();
}

class _PraiseFeedbackSheetState extends State<_PraiseFeedbackSheet> {
  int? _stars;
  String? _emojiKey;

  static const _starColor = Color(0xFFFFB800);

  void _pickStar(int n) {
    setState(() {
      _stars = n;
      _emojiKey = null;
    });
  }

  void _pickEmoji(String key) {
    setState(() {
      _emojiKey = key;
      _stars = null;
    });
  }

  void _submit() {
    final s = _stars;
    final e = _emojiKey;
    if (s != null) {
      Navigator.of(context).pop('praise:star:$s');
      return;
    }
    if (e != null) {
      Navigator.of(context).pop('praise:emoji:$e');
    }
  }

  bool get _canSubmit => _stars != null || _emojiKey != null;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.feedbackPraiseTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.feedbackPraiseStarsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final n = i + 1;
                final on = _stars != null && n <= _stars!;
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 36,
                  onPressed: () => _pickStar(n),
                  icon: Icon(
                    on ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: on ? _starColor : Colors.grey.shade400,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feedbackPraiseEmojiHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: _praiseEmojiKeys.map((pair) {
                final key = pair.$1;
                final ch = pair.$2;
                final sel = _emojiKey == key;
                return Material(
                  color: sel
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _pickEmoji(key),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        ch,
                        style: TextStyle(
                          fontSize: 34,
                          height: 1,
                          decoration: sel ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: _feedbackSendButtonStyle(),
              child: Text(l10n.feedbackSend),
            ),
          ],
        ),
      ),
    );
  }
}
