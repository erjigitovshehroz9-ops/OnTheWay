import 'package:flutter/material.dart';

/// Shows the real [error] and [stackTrace] from Riverpod [AsyncValue] / [.when].
class ProviderErrorScreen extends StatelessWidget {
  const ProviderErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
    this.onRetry,
    this.title = 'Xatolik',
  });

  final Object error;
  final StackTrace stackTrace;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                error.toString(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              SelectableText(
                stackTrace.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Qayta urinish'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
