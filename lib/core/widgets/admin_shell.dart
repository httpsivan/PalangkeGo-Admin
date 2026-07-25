import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/mock_repository.dart';
import '../theme/theme_controller.dart';
import 'admin_widgets.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;
  static const navItems = [
    ('Overview', '/overview', Icons.home_outlined),
    ('Accounts', '/accounts', Icons.people_outline_rounded),
    ('Vendor Application', '/applications', Icons.verified_user_outlined),
    ('Renewal', '/renewal', Icons.campaign_outlined),
    ('Reports', '/reports', Icons.insert_chart_outlined_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _MobileDrawer(current: current),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _TopNavigation(current: current),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TopNavigation extends ConsumerWidget {
  const _TopNavigation({required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: BoxDecoration(
        color: semanticColors(context).heroBackground,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(.18)),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(alignment: Alignment.centerLeft, child: AppLogo()),
          if (!compact)
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in AdminShell.navItems)
                      _NavItem(
                        label: item.$1,
                        path: item.$2,
                        icon: item.$3,
                        active: current == item.$2,
                      ),
                  ],
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Open navigation',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    ),
                  ),
                  const _NotificationButton(),
                  const SizedBox(width: 10),
                  _ProfileMenu(compact: true),
                ],
              ),
            ),
          if (!compact)
            const Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NotificationButton(),
                  SizedBox(width: 10),
                  _ProfileMenu(compact: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.active,
  });
  final String label;
  final String path;
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Material(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: () => context.go(path),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: active
                        ? semanticColors(context).heroBackground
                        : Colors.white.withOpacity(.7),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? semanticColors(context).heroBackground
                          : Colors.white.withOpacity(.78),
                      fontSize: 11.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();
  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withOpacity(.13),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                  const SnackBar(content: Text('No new notifications'))),
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
                border: Border.all(
                  color: semanticColors(context).heroBackground,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider);
    final resolved = MediaQuery.platformBrightnessOf(context);
    return PopupMenuButton<String>(
      tooltip: 'Account and appearance',
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        } else if (value == 'quick') {
          await ref.read(themeModeProvider.notifier).toggleResolved(resolved);
        } else if (value.startsWith('theme:')) {
          final mode = ThemeMode.values.firstWhere(
            (item) => item.name == value.substring(6),
          );
          await ref.read(themeModeProvider.notifier).setMode(mode);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Kirren Michael Fraginal',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'quick',
          child: Row(
            children: [
              Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 17,
              ),
              const SizedBox(width: 9),
              const Text('Quick appearance toggle'),
            ],
          ),
        ),
        for (final option in [
          (ThemeMode.light, Icons.light_mode_outlined, 'Light'),
          (ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
          (ThemeMode.system, Icons.settings_suggest_outlined, 'System'),
        ])
          PopupMenuItem(
            value: 'theme:${option.$1.name}',
            child: Row(
              children: [
                Icon(option.$2, size: 17),
                const SizedBox(width: 9),
                Expanded(child: Text(option.$3)),
                if (selected == option.$1)
                  const Icon(Icons.check_rounded, size: 16),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: Text('Log out')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AvatarCircle(name: 'Kirren Michael Fraginal', size: 34),
          if (!compact) ...[
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kirren Michael Fraginal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Administrator',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 17,
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileDrawer extends ConsumerWidget {
  const _MobileDrawer({required this.current});
  final String current;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
        backgroundColor: semanticColors(context).elevatedSurface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const AppLogo(compact: true),
                    const SizedBox(width: 10),
                    const Text(
                      'PalengkeGo Admin',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
              ),
              const Divider(),
              for (final item in AdminShell.navItems)
                ListTile(
                  leading: Icon(item.$3),
                  title: Text(item.$1),
                  selected: current == item.$2,
                  selectedColor: semanticColors(context).heroBackground,
                  selectedTileColor: semanticColors(context).successContainer,
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.$2);
                  },
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showThemeSelector(context, ref),
                icon: const Icon(Icons.palette_outlined),
                label: const Text('Appearance'),
              ),
            ],
          ),
        ),
      );
}

void showThemeSelector(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              groupValue: ref.read(themeModeProvider),
              title: Text(mode.name),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setMode(value);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
    ),
  );
}

Future<T?> showBlurredDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool barrierDismissible = true,
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Close dialog',
      barrierColor: semanticColors(context).overlayScrim,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: builder(context),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .97, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
