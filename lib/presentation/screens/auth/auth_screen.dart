import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/glass_panel.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreatingAccount = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authActionProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    final authAction = ref.watch(authActionProvider);
    final isLoading = authAction.isLoading;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 520
                  ? 44.0
                  : 22.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 44,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 24 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: GlassPanel(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BrandHeader(
                                  isCreatingAccount: _isCreatingAccount,
                                ),
                                const SizedBox(height: 28),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 240),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _isCreatingAccount
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: TextFormField(
                                            key: const ValueKey('nameField'),
                                            controller: _nameController,
                                            textInputAction:
                                                TextInputAction.next,
                                            decoration: const InputDecoration(
                                              labelText: 'Full name',
                                              prefixIcon: Icon(
                                                Icons.badge_outlined,
                                              ),
                                            ),
                                            validator: _isCreatingAccount
                                                ? _validateName
                                                : null,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                    ),
                                  ),
                                  validator: _validateEmail,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                  onFieldSubmitted: (_) => _submitEmailAuth(),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _submitEmailAuth,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: isLoading
                                        ? const SizedBox.square(
                                            key: ValueKey('emailLoading'),
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                            ),
                                          )
                                        : Text(
                                            key: const ValueKey('emailLabel'),
                                            _isCreatingAccount
                                                ? 'Create secure account'
                                                : 'Sign in securely',
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const _DividerLabel(label: 'or'),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () => ref
                                            .read(authActionProvider.notifier)
                                            .signInWithGoogle(),
                                  icon: const Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 30,
                                  ),
                                  label: const Text('Continue with Google'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withValues(alpha: 0.36),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextButton(
                                  onPressed: isLoading ? null : _toggleMode,
                                  child: Text(
                                    _isCreatingAccount
                                        ? 'Already have an account? Sign in'
                                        : 'New here? Create an account',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _isCreatingAccount = !_isCreatingAccount;
    });
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(authActionProvider.notifier);

    if (_isCreatingAccount) {
      await controller.createAccountWithEmail(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      return;
    }

    await controller.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Enter your name.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) {
      return 'Use at least 6 characters.';
    }

    return null;
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isCreatingAccount});

  final bool isCreatingAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 72),
        const SizedBox(height: 22),
        Text(
          'Stealthera',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            key: ValueKey(isCreatingAccount),
            isCreatingAccount
                ? 'Create your protected health workspace.'
                : 'Sign in to your health workspace.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }
}
