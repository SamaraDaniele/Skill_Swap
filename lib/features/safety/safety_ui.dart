import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../matches/matches.dart';
import 'safety.dart';

extension ReportReasonLabel on ReportReason {
  String label(AppLocalizations l10n) => switch (this) {
    ReportReason.harassment => l10n.reportReasonHarassment,
    ReportReason.spam => l10n.reportReasonSpam,
    ReportReason.inappropriate => l10n.reportReasonInappropriate,
    ReportReason.fake => l10n.reportReasonFake,
    ReportReason.offensive => l10n.reportReasonOffensive,
    ReportReason.scam => l10n.reportReasonScam,
    ReportReason.other => l10n.reportReasonOther,
  };
}

Future<bool> confirmSafetyAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showReportSheet(
  BuildContext context, {
  required String me,
  required String otherId,
  required String otherName,
  Match? match,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReportSheet(
      me: me,
      otherId: otherId,
      otherName: otherName,
      match: match,
    ),
  );
  return sent ?? false;
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.me,
    required this.otherId,
    required this.otherName,
    required this.match,
  });

  final String me;
  final String otherId;
  final String otherName;
  final Match? match;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _submitted = false;
  bool _isSending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    final reason = _reason;
    if (reason == null || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(
            me: widget.me,
            other: widget.otherId,
            reason: reason,
            details: _details.text,
            match: widget.match,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportTitle(widget.otherName),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.reportIntro,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: reason,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason.label(l10n)),
                    ),
                ],
              ),
            ),
            if (_submitted && _reason == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.reportPickReason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _details,
              maxLength: SafetyRepository.maxDetailsLength,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.reportDetailsLabel,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: l10n.reportSubmitAction,
              isLoading: _isSending,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
