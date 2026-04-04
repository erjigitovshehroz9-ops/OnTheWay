import 'package:flutter/material.dart';

/// Minimal app shell when bootstrap (e.g. native DB init) fails before [runApp].
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({
    super.key,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Xatolik')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              '${error.toString()}\n\n${stackTrace ?? ''}',
            ),
          ),
        ),
      ),
    );
  }
}
