import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/animations/animated_widgets.dart';
import '../../core/animations/app_motion.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _loginSlides = <String>[
    'assets/images/naga_city_mall.jpg',
    'assets/images/fruit_stall.jpg',
    'assets/images/meat_stall.jpg',
    'assets/images/seafood_stall.jpg',
    'assets/images/sari_sari_stall.jpg',
    'assets/images/fish_market.jpg',
    'assets/images/dried_fish_stall.jpg',
    'assets/images/vegetable_stall.jpg',
    'assets/images/market_background.png',
  ];

  final formKey = GlobalKey<FormState>();
  // Demo credentials prefill only in demo mode — Firebase mode must never
  // pre-fill a real administrator's password.
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  bool keepSignedIn = false;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (!ref.read(firebaseEnabledProvider)) {
      email.text = defaultAdminEmail;
      password.text = defaultAdminPassword;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final path in _loginSlides) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => error = null);
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    final result = await ref
        .read(authProvider.notifier)
        .login(email.text, password.text, keepSignedIn);
    if (!mounted) return;
    setState(() {
      loading = false;
      error = result;
    });
    if (result == null) {
      context.go('/overview');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  static final _loginThemeData = buildLightTheme();

  @override
  Widget build(BuildContext context) {
    return Theme(
      // The login screen intentionally stays light even when the dashboard
      // theme preference is dark.
      data: _loginThemeData,
      child: Builder(
        builder: (loginContext) {
          final narrow = MediaQuery.sizeOf(loginContext).width < 820;
          final body = narrow
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      _market(loginContext, true),
                      _loginForm(loginContext),
                    ],
                  ),
                )
              : SizedBox.expand(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 51, child: _market(loginContext, false)),
                      Expanded(flex: 49, child: _loginForm(loginContext)),
                    ],
                  ),
                );
          return Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  const _Header(dark: false),
                  Expanded(child: body),
                  const _Footer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _market(BuildContext context, bool compact) {
    return Container(
      height: compact ? 245 : double.infinity,
      constraints: const BoxConstraints(minHeight: 245),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: semanticColors(context).heroBackground,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: const _LoginSlideshow(images: _loginSlides),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: semanticColors(context).heroBackground.withValues(alpha: .68),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 28 : 36,
              compact ? 34 : 150,
              30,
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NAGA CITY PEOPLE’S MALL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Skip the Roam,\nOrder from Home.',
                  style: GoogleFonts.radley(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginForm(BuildContext context) {
    final colors = semanticColors(context);
    final form = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back, Admin!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: colors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Authorized personnel only',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 14),
          _ModeBadge(firebase: ref.read(firebaseEnabledProvider)),
          const SizedBox(height: 24),
          const Text(
            'Email Address',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'name@nagacity.gov.ph',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email address';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: password,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => submit(),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // "Keep me signed in" only exists in demo mode; in Firebase
              // mode the Auth SDK persists the session itself.
              if (!ref.read(firebaseEnabledProvider)) ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: keepSignedIn,
                    onChanged: (value) =>
                        setState(() => keepSignedIn = value ?? false),
                  ),
                ),
                const Text('Keep me signed in', style: TextStyle(fontSize: 11)),
              ],
              const Spacer(),
              TextButton(
                onPressed: () => _forgot(context),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          if (error != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.dangerContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error!,
                style: TextStyle(color: colors.danger, fontSize: 11),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: AnimatedButtonFeedback(
              enabled: !loading,
              child: FilledButton(
                onPressed: loading ? null : submit,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.heroBackground,
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Log In'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    final panel = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: form,
          ),
        ),
      ),
    );
    final animatedPanel = FadeSlideIn(
      begin: const Offset(0, .035),
      child: panel,
    );
    return MediaQuery.sizeOf(context).width >= 820
        ? SizedBox.expand(child: animatedPanel)
        : animatedPanel;
  }

  Future<void> _forgot(BuildContext context) async {
    final controller = TextEditingController(text: email.text);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Administrator email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'If the account exists, a reset link has been sent.',
                  ),
                ),
              );
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _LoginSlideshow extends StatefulWidget {
  const _LoginSlideshow({required this.images});

  final List<String> images;

  @override
  State<_LoginSlideshow> createState() => _LoginSlideshowState();
}

class _LoginSlideshowState extends State<_LoginSlideshow> {
  static const _slideInterval = Duration(seconds: 5);
  static const _fadeDuration = Duration(milliseconds: 1000);

  Timer? _timer;
  int _currentIndex = 0;
  bool _preloadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preloadStarted) return;
    _preloadStarted = true;
    unawaited(_preloadImagesAndStart());
  }

  Future<void> _preloadImagesAndStart() async {
    await Future.wait(
      widget.images.map(
        (imagePath) => precacheImage(AssetImage(imagePath), context),
      ),
    );
    if (!mounted || widget.images.length < 2) return;
    _timer = Timer.periodic(_slideInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotion.reducedMotion(context);
    return AnimatedSwitcher(
      duration: reducedMotion ? AppMotion.instant : _fadeDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: Image.asset(
        widget.images[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        gaplessPlayback: true,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final bg = dark ? colors.heroBackground : Theme.of(context).colorScheme.surface;
    return Container(
      height: 78,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
            color: dark ? colors.borderOnHero : colors.subtleBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          AppLogo(dark: dark, showAdminBadge: true),
          const Spacer(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(
                    'Home',
                    style: TextStyle(
                      color: dark ? Colors.white70 : colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(
                    'About',
                    style: TextStyle(
                      color: dark ? Colors.white70 : colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      color: dark ? Colors.white70 : colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.get_app_rounded, size: 18),
                  label: const Text(
                    'Install App',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: semanticColors(context).subtleBorder),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/naga_city_seal.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      semanticLabel: 'City of Naga official seal',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Naga City People’s Mall — Market Enterprise and Promotions Office (MEPO)',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width > 560) ...[
              TextButton(
                onPressed: () {},
                child: const Text('Privacy Policy',
                    style: TextStyle(fontSize: 10)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Support', style: TextStyle(fontSize: 10)),
              ),
            ],
          ],
        ),
      );
}

/// Honest mode indicator — demo (seeded data) vs live Firebase. Civic
/// clarity over decoration: a quiet pill, no glass, no gradients.
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.firebase});

  final bool firebase;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: firebase ? colors.successContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: firebase ? colors.success : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            firebase ? Icons.verified_outlined : Icons.science_outlined,
            size: 12,
            color: firebase ? colors.success : colors.mutedText,
          ),
          const SizedBox(width: 6),
          Text(
            firebase ? 'Live · City of Naga market data' : 'Demo · seeded data',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
              color: firebase ? colors.success : colors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
