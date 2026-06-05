import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/glow_card.dart';
import '../../blocs/auth/auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isCreating = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final bloc = context.read<AuthBloc>();
    if (_isCreating) {
      bloc.add(
        AuthEmailSignUpRequested(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        ),
      );
    } else {
      bloc.add(
        AuthEmailSignInRequested(email: _email.text, password: _password.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (p, n) =>
                n.action == AuthAction.failure && n.errorMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            },
            builder: (context, state) {
              final loading = state.isSubmitting;
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: GlowCard(
                          glow: true,
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const BrandMark(size: 66),
                                const SizedBox(height: 22),
                                Text(
                                  'Stealthera',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isCreating
                                      ? 'Create your protected health workspace.'
                                      : 'Sign in to your health workspace.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  child: _isCreating
                                      ? Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: TextFormField(
                                            controller: _name,
                                            textInputAction: TextInputAction.next,
                                            decoration: const InputDecoration(
                                              labelText: 'Full name',
                                              prefixIcon: Icon(Icons.badge_outlined),
                                            ),
                                            validator: (v) =>
                                                (v ?? '').trim().length < 2
                                                    ? 'Enter your name.'
                                                    : null,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email address',
                                    prefixIcon: Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: (v) {
                                    final email = (v ?? '').trim();
                                    return (!email.contains('@') ||
                                            !email.contains('.'))
                                        ? 'Enter a valid email.'
                                        : null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v ?? '').length < 6
                                      ? 'Use at least 6 characters.'
                                      : null,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 22),
                                ElevatedButton(
                                  onPressed: loading ? null : _submit,
                                  child: loading
                                      ? const SizedBox.square(
                                          dimension: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Color(0xFF15161C),
                                          ),
                                        )
                                      : Text(
                                          _isCreating
                                              ? 'Create secure account'
                                              : 'Sign in securely',
                                        ),
                                ),
                                const SizedBox(height: 18),
                                _OrDivider(),
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  onPressed: loading
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                          const AuthGoogleSignInRequested(),
                                        ),
                                  icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                                  label: const Text('Continue with Google'),
                                ),
                                const SizedBox(height: 14),
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => setState(
                                          () => _isCreating = !_isCreating,
                                        ),
                                  child: Text(
                                    _isCreating
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
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Row(
      children: [
        Expanded(child: Divider(color: color)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Divider(color: color)),
      ],
    );
  }
}
