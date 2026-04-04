import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/job_transport_type.dart';
import 'courier_registration_transport_row.dart';

/// Sender → Courier o‘tishda transport tanlanmagan bo‘lsa, ro‘yxatdan o‘tishdagi
/// icon qatori bilan bir xil UI.
/// [profileEditMode] — kuryer profilidan transportni yangilash (sarlavha va tugma matni).
Future<bool?> showCourierTransportSetupBottomSheet({
  required BuildContext context,
  required String userId,
  bool profileEditMode = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Theme(
      data: Theme.of(ctx).copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        bottomSheetTheme: Theme.of(ctx).bottomSheetTheme.copyWith(
          backgroundColor: Colors.white,
          modalBackgroundColor: Colors.white,
          elevation: 0,
          modalElevation: 0,
          shadowColor: Colors.transparent,
        ),
        colorScheme: Theme.of(ctx).colorScheme.copyWith(
          surface: Colors.white,
          onSurface: const Color(0xFF111827),
        ),
      ),
      child: CourierTransportSetupSheet(
        userId: userId,
        profileEditMode: profileEditMode,
      ),
    ),
  );
}

class CourierTransportSetupSheet extends ConsumerStatefulWidget {
  const CourierTransportSetupSheet({
    super.key,
    required this.userId,
    this.profileEditMode = false,
  });

  final String userId;
  final bool profileEditMode;

  @override
  ConsumerState<CourierTransportSetupSheet> createState() =>
      _CourierTransportSetupSheetState();
}

class _CourierTransportSetupSheetState
    extends ConsumerState<CourierTransportSetupSheet> {
  final Set<String> _selected = <String>{};
  bool _attemptedContinue = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future(() async {
      final auth = await ref.read(authRepositoryProvider.future);
      if (!mounted) return;
      final existing =
          await auth.effectiveCourierTransportKeys(widget.userId);
      if (existing.isEmpty) return;
      setState(() {
        _selected
          ..clear()
          ..addAll(existing);
      });
    });
  }

  Future<void> _onContinue() async {
    setState(() {
      _attemptedContinue = true;
      _error = null;
    });
    if (_selected.isEmpty) return;

    setState(() => _saving = true);
    try {
      final auth = await ref.read(authRepositoryProvider.future);
      await auth.saveProfileTransportTypes(
        widget.userId,
        _selected.toList(growable: false),
      );
      await ref.read(authSessionProvider.notifier).refresh();
      ref.invalidate(courierJobsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('saveProfileTransportTypes: $e\n$st');
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.profileEditMode
                ? l10n.courierTransportSheetTitleProfile
                : l10n.courierTransportSheetTitleSetup,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF103B8F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.courierTransportEmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 18),
          CourierRegistrationTransportRow(
            selected: _selected,
            showValidationError: _attemptedContinue && _selected.isEmpty,
            onToggle: (value) {
              setState(() {
                if (_selected.contains(value)) {
                  _selected.remove(value);
                } else {
                  _selected.add(value);
                }
              });
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: CourierRegistrationTransportRow.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF003A90),
                    disabledForegroundColor:
                        const Color(0xFF003A90).withValues(alpha: 0.45),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF003A90),
                      width: 1.4,
                    ),
                  ),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving ? null : _onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF003A90),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF003A90).withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.profileEditMode
                              ? l10n.save
                              : l10n.continueWord,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
