import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  ];

  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  Timer? _slideTimer;
  int _slideIndex = 0;
  bool obscure = true;
  bool keepSignedIn = false;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _slideIndex = (_slideIndex + 1) % _loginSlides.length);
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
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
    if (result == null) context.go('/overview');
    if (result != null)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 820;
    final body = narrow
        ? SingleChildScrollView(
            child: Column(
              children: [_market(context, true), _loginForm(context)],
            ),
          )
        : SizedBox.expand(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 51, child: _market(context, false)),
                Expanded(flex: 49, child: _loginForm(context)),
              ],
            ),
          );
    return Scaffold(
      body: Column(
        children: [
          _Header(dark: Theme.of(context).brightness == Brightness.dark),
          Expanded(child: body),
          const _Footer(),
        ],
      ),
    );
  }

  Widget _market(BuildContext context, bool compact) {
    return Container(
      height: compact ? 245 : double.infinity,
      constraints: const BoxConstraints(minHeight: 245),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1600),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation.drive(
                  CurveTween(curve: Curves.easeInOut),
                ),
                child: child,
              ),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: SizedBox.expand(
                child: Image.asset(
                  _loginSlides[_slideIndex],
                  key: ValueKey(_loginSlides[_slideIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: semanticColors(context).heroBackground.withOpacity(.68),
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
                    color: const Color(0xB3FFFFFF),
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
                    fontSize: 34,
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
    final form = Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back, Admin!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.heroBackground,
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
          const SizedBox(height: 34),
          const Text(
            'Email Address',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'name@nagacity.gov.ph',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'Enter your email address';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim()))
                return 'Enter a valid email address';
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
          const SizedBox(height: 16),
          const Text(
            'Mock credentials: admin@palengkego.gov.ph / Admin123!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
    final panel = Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: form,
        ),
      ),
    );
    return MediaQuery.sizeOf(context).width >= 820
        ? SizedBox.expand(child: panel)
        : panel;
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

class _Header extends StatelessWidget {
  const _Header({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: dark ? semanticColors(context).heroBackground : Colors.white,
          border: Border(
            bottom: BorderSide(color: semanticColors(context).subtleBorder),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/market_basket.png',
              width: 64,
              height: 48,
              fit: BoxFit.contain,
              semanticLabel: 'Market basket',
            ),
            const SizedBox(width: 8),
            Image.asset(
              'assets/images/palengkego_logo.png',
              width: 180,
              height: 48,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'PalengkeGo',
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Home')),
            TextButton(onPressed: () {}, child: const Text('About')),
            TextButton(onPressed: () {}, child: const Text('Contact')),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () {},
              child: const Text('Install App', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.65),
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
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Support',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
}
