import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import 'auth_repository.dart';
import 'auth_validators.dart';
import 'neon_auth_widgets.dart';
import 'password_reset_dialog.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      _isSignUp
          ? await repo.signUp(email: _email.text, password: _password.text)
          : await repo.signIn(email: _email.text, password: _password.text);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => PasswordResetDialog(initialEmail: _email.text),
    );
    if (sent != true || !mounted) return;
    showAppSnackBar(context, context.l10n.resetPasswordSent);
  }

  void _toggleMode() {
    final email = _email.text;
    final password = _password.text;
    _formKey.currentState?.reset();
    _email.text = email;
    _password.text = password;
    setState(() => _isSignUp = !_isSignUp);
  }

  void _socialSoon() => showAppSnackBar(context, context.l10n.socialSignInSoon);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: NeonBackdropPainter()),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.sm,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AutofillGroup(
                      child: Form(key: _formKey, child: _content(l10n)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n) {
    final password = NeonTextField(
      controller: _password,
      hint: l10n.passwordLabel,
      icon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      isPassword: true,
      textInputAction: TextInputAction.done,
      autofillHints: [
        _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
      ],
      onFieldSubmitted: (_) => _submit(),
      validator: (value) =>
          (value?.length ?? 0) >= 6 ? null : l10n.validationPassword,
      suffix: IconButton(
        tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
        color: const Color(0xFFE6E6E6),
        iconSize: 25,
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(child: SkillSwapLogo(semanticLabel: l10n.appTitle)),
        const SizedBox(height: 30),
        Semantics(
          header: true,
          child: Text(
            _isSignUp ? l10n.signUpTitle : l10n.signInTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authTagline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: NeonColors.muted,
            fontSize: 16.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 22),
        const Center(child: NeonGlowBar()),
        const SizedBox(height: 22),
        GlassNeonCard(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeonTextField(
                      controller: _email,
                      hint: l10n.emailLabel,
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          isValidEmail(value) ? null : l10n.validationEmail,
                    ),
                    const SizedBox(height: 14),
                    password,
                  ],
                ),
              ),
              const SizedBox(height: 24),
              NeonPrimaryButton(
                label: _isSignUp ? l10n.signUpAction : l10n.signInAction,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              if (!_isSignUp) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                const SizedBox(height: 4),
              ] else
                const SizedBox(height: 22),
              NeonOrDivider(label: l10n.orSeparator),
              const SizedBox(height: 16),
              SocialSignInButton(
                label: l10n.continueWithGoogle,
                leading: const GoogleGMark(size: 24),
                onPressed: _isLoading ? null : _socialSoon,
              ),
              const SizedBox(height: 12),
              SocialSignInButton(
                label: l10n.continueWithApple,
                leading: const Icon(
                  Icons.apple,
                  size: 28,
                  color: AppColors.white,
                ),
                onPressed: _isLoading ? null : _socialSoon,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isSignUp ? l10n.haveAccountPrompt : l10n.newHerePrompt,
              style: const TextStyle(color: AppColors.white, fontSize: 17),
            ),
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              style: TextButton.styleFrom(
                foregroundColor: NeonColors.lime,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(_isSignUp ? l10n.signInAction : l10n.signUpAction),
            ),
          ],
        ),
      ],
    );
  }
}
