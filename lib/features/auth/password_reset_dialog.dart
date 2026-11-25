import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import 'auth_repository.dart';
import 'auth_validators.dart';

class PasswordResetDialog extends ConsumerStatefulWidget {
  const PasswordResetDialog({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<PasswordResetDialog> createState() =>
      _PasswordResetDialogState();
}

class _PasswordResetDialogState extends ConsumerState<PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = context.l10n.failureMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isSending,
      child: AlertDialog(
        title: Text(l10n.resetPasswordTitle),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.resetPasswordBody),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                autofocus: widget.initialEmail.isEmpty,
                enabled: !_isSending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  errorText: _error,
                  errorMaxLines: 3,
                ),
                validator: (value) =>
                    isValidEmail(value) ? null : l10n.validationEmail,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onFieldSubmitted: (_) => _send(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSending
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: _isSending ? null : _send,
            child: _isSending
                ? Semantics(
                    label: l10n.sendAction,
                    child: const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(l10n.sendAction),
          ),
        ],
      ),
    );
  }
}
