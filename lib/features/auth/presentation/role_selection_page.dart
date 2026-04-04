import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/provider_error_screen.dart';
import '../../../core/providers/core_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/user_role.dart';
import '../../../repositories/auth_repository.dart';
import '../../../shared/widgets/app_theme_picker_sheet.dart';
import '../../../shared/widgets/language_switcher_button.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  UserRole? _selected;
  bool _loading = false;

  Future<void> _confirm(AuthRepository repo) async {
    final role = _selected;
    if (role == null) return;
    setState(() => _loading = true);
    try {
      await repo.setRole(role);
      await ref.read(authSessionProvider.notifier).refresh();
    } catch (e, st) {
      debugPrint('setRole: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repoAsync = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chooseRoleTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: l10n.createJobMenuChangeTheme,
            onPressed: () => showAppThemeBottomSheet(context),
          ),
          const LanguageSwitcherButton(),
        ],
      ),
      body: SafeArea(
        child: repoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ProviderErrorScreen(
                error: error,
                stackTrace: stack,
                onRetry: () => ref.invalidate(authRepositoryProvider),
              ),
          data: (repo) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.chooseRoleSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _RoleCard(
                    title: l10n.roleCourier,
                    subtitle: l10n.roleCourierDesc,
                    icon: Icons.delivery_dining_rounded,
                    selected: _selected == UserRole.courier,
                    onTap: () => setState(() => _selected = UserRole.courier),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    title: l10n.roleSender,
                    subtitle: l10n.roleSenderDesc,
                    icon: Icons.inventory_2_rounded,
                    selected: _selected == UserRole.sender,
                    onTap: () => setState(() => _selected = UserRole.sender),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed:
                        _loading || _selected == null ? null : () => _confirm(repo),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.continueWord),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withOpacity(0.35)
          : scheme.surfaceContainerHighest.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      elevation: selected ? 2 : 0,
      shadowColor: scheme.shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
