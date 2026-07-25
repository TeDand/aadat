import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _awaitingConfirmation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        // No session means email confirmation is required before sign-in works.
        if (response.session == null && mounted) {
          setState(() => _awaitingConfirmation = true);
        }
        // If session exists, AuthGate's StreamBuilder will navigate automatically.
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _awaitingConfirmation
                ? _buildConfirmationScreen(scheme, textTheme)
                : _buildAuthForm(scheme, textTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationScreen(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wordmark(scheme, textTheme),
        const SizedBox(height: 40),
        Icon(Icons.mark_email_unread_outlined,
            size: 40, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'A confirmation link has been sent to ${_emailController.text.trim()}. '
          'Click it to activate your account, then sign in.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => setState(() {
            _awaitingConfirmation = false;
            _isSignUp = false;
            _error = null;
          }),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Go to Sign In'),
        ),
      ],
    );
  }

  Widget _buildAuthForm(ColorScheme scheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wordmark(scheme, textTheme),
        const SizedBox(height: 40),
        Text(
          _isSignUp ? 'Create an account' : 'Sign in to continue',
          style: textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _isSignUp = !_isSignUp;
            _error = null;
          }),
          child: Text(
            _isSignUp
                ? 'Already have an account? Sign In'
                : "Don't have an account? Sign Up",
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordmark(ColorScheme scheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '>_',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.35),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'aadat',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
