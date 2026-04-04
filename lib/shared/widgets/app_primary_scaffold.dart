import 'package:flutter/material.dart';

import 'language_switcher_button.dart';

class AppPrimaryScaffold extends StatelessWidget {
  const AppPrimaryScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.showLanguageSwitcher = true,
    this.showAppBarTitle = true,
    this.showAppBar = true,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final bool showLanguageSwitcher;

  /// `false` bo‘lsa, AppBar’da sarlavha matni ko‘rsatilmaydi (faqat amallar qoladi).
  final bool showAppBarTitle;

  /// `SafeArea` ichida emas — ekran pastki chetigacha cho‘zish uchun.
  final Widget? bottomNavigationBar;

  /// `false` bo‘lsa AppBar chiqarilmaydi (masalan, amallar body header ichida bo‘lganda).
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: showAppBarTitle ? Text(title) : const SizedBox.shrink(),
              actions: [
                if (showLanguageSwitcher) const LanguageSwitcherButton(),
                ...actions,
              ],
            )
          : null,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(child: body),
    );
  }
}
