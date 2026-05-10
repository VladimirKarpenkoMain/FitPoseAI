import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          HistoryScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5EAF1)),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 82,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            indicatorColor: const Color(0xFFFFE0CC),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);

              return TextStyle(
                color: selected
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);

              return IconThemeData(
                color: selected
                    ? const Color(0xFF7A3411)
                    : const Color(0xFF64748B),
                size: 22,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              if (index == currentIndex) {
                return;
              }

              context.go(index == 0 ? '/home' : '/history');
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
                label: l10n.navHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
