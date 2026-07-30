import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories/mock_repository.dart';
import '../animations/animated_widgets.dart';
import '../animations/app_motion.dart';
import '../theme/theme_controller.dart';
import 'admin_widgets.dart';
import 'admin_profile_menu.dart';
import 'notification_panel.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;
  static const navItems = [
    ('Overview', '/overview', Icons.home_outlined),
    ('Accounts', '/accounts', Icons.people_outline_rounded),
    ('Vendor Application', '/applications', Icons.verified_user_outlined),
    ('Renewal', '/renewal', Icons.campaign_outlined),
    ('Reports', '/reports', Icons.insert_chart_outlined_rounded),
    ('Audit Log', '/audit-log', Icons.history_rounded),
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
            Expanded(
              child: AnimatedPageSwitcher(route: current, child: child),
            ),
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
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: BoxDecoration(
        color: semanticColors(context).heroBackground,
        border: Border(
          bottom: BorderSide(color: semanticColors(context).borderOnHero),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Open navigation',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    ),
                  ),
                  const _ThemeToggleButton(),
                  const SizedBox(width: 6),
                  const NotificationBell(),
                  const SizedBox(width: 10),
                  AdminProfileMenu(compact: true),
                ],
              ),
            ),
          if (!compact)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _ThemeToggleButton(),
                  const SizedBox(width: 6),
                  NotificationBell(),
                  SizedBox(width: 10),
                  AdminProfileMenu(compact: false),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
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
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final activeColor =
        widget.active ? colors.activeNavigationText : colors.heroMuted;
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedScale(
          scale: pressed ? .97 : 1,
          duration: AppMotion.duration(context, AppMotion.press),
          curve: AppMotion.easeOut,
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.indicator),
            curve: AppMotion.easeOut,
            decoration: BoxDecoration(
              color:
                  widget.active ? colors.activeNavigation : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: InkWell(
              onTap: () => context.go(widget.path),
              onTapDown: (_) => setState(() => pressed = true),
              onTapUp: (_) => setState(() => pressed = false),
              onTapCancel: () => setState(() => pressed = false),
              borderRadius: BorderRadius.circular(22),
              hoverColor: colors.navigationHover,
              splashColor: colors.activeNavigation.withOpacity(.16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: activeColor),
                      duration:
                          AppMotion.duration(context, AppMotion.indicator),
                      builder: (context, color, child) => Icon(
                        widget.icon,
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 7),
                    AnimatedDefaultTextStyle(
                      duration:
                          AppMotion.duration(context, AppMotion.indicator),
                      curve: AppMotion.easeOut,
                      style: GoogleFonts.inter(
                        color: activeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = semanticColors(context);
    return Tooltip(
      message: dark ? 'Switch to light mode' : 'Switch to dark mode',
      child: Material(
        color: colors.navigationControl,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => ref
              .read(themeModeProvider.notifier)
              .toggleResolved(Theme.of(context).brightness),
          hoverColor: colors.navigationHover,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: AnimatedSwitcher(
              duration: AppMotion.duration(context, AppMotion.component),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween<double>(begin: -.12, end: 0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(dark),
                color: colors.heroForeground,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();
  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: semanticColors(context).navigationControl,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => showNotificationsDialog(context),
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: semanticColors(context).heroForeground,
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
                color: semanticColors(context).danger,
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
    final profile = ref.watch(adminProfileProvider);
    final colors = semanticColors(context);
    final selected = ref.watch(themeModeProvider);
    final resolved = MediaQuery.platformBrightnessOf(context);
    return PopupMenuButton<String>(
      tooltip: 'Account and appearance',
      offset: const Offset(0, 54),
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
        } else if (value == 'settings') {
          await showAccountSettingsDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.manage_accounts_outlined, size: 17),
              SizedBox(width: 9),
              Text('Account settings'),
            ],
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarCircle(
            name: profile.name,
            size: 34,
            imageBytes: profile.avatarBytes,
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: colors.heroForeground,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Administrator',
                    style: TextStyle(color: colors.heroMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.heroMuted,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> showAccountSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const _AccountSettingsDialog(),
  );
}

class _AccountSettingsDialog extends ConsumerStatefulWidget {
  const _AccountSettingsDialog();

  @override
  ConsumerState<_AccountSettingsDialog> createState() =>
      _AccountSettingsDialogState();
}

class _AccountSettingsDialogState
    extends ConsumerState<_AccountSettingsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(adminProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    if (password.isNotEmpty && password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(adminProfileProvider.notifier).updateProfile(
          name: name,
          password: password.isEmpty ? null : password,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account settings updated.')),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Account settings'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change password',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  hintText: 'Leave blank to keep current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: semanticColors(context).danger,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
        ],
      );
}

void showNotificationsDialog(BuildContext context) {
  showBlurredDialog<void>(
    context,
    (context) => const _NotificationsDialog(),
  );
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: semanticColors(context).successContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: semanticColors(context).success,
                      ),
                      const SizedBox(width: 11),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Market Guidelines',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Updated safety protocols are available for the upcoming weekend market.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
      transitionDuration: AppMotion.duration(context, AppMotion.dialog),
      pageBuilder: (context, animation, secondaryAnimation) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: builder(context),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.easeOut,
        );
        if (AppMotion.reducedMotion(context)) {
          return FadeTransition(opacity: curved, child: child);
        }
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .015),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
