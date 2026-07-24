import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/report_viewmodel.dart';

/// CNG LIVE — Report Wrong Update Screen (Step 2)
///
/// Reached from Pump Detail's "Report Wrong Update" action against the
/// most recent status update. Filing a report also flags that update
/// server-side (see ReportRemoteDataSource.submitReport).
class ReportWrongUpdateScreen extends StatefulWidget {
  const ReportWrongUpdateScreen({super.key});

  @override
  State<ReportWrongUpdateScreen> createState() =>
      _ReportWrongUpdateScreenState();
}

class _ReportWrongUpdateScreenState extends State<ReportWrongUpdateScreen> {
  static const _reasons = [
    'Status is outdated',
    'Wrong queue length',
    'Pump was closed',
    'Incorrect stock status',
    'Other',
  ];

  String? _selectedReason;
  String? _pumpId;
  String? _statusUpdateId;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsRead) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _pumpId = args['pumpId'] as String?;
        _statusUpdateId = args['statusUpdateId'] as String?;
      }
      _argsRead = true;
    }
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    final pumpId = _pumpId;
    final statusUpdateId = _statusUpdateId;
    final userId = context.read<AuthViewModel>().user?.id;

    if (reason == null || pumpId == null || statusUpdateId == null || userId == null) {
      context.showAppSnackBar('Please select a reason.');
      return;
    }

    final success = await context.read<ReportViewModel>().submitReport(
          statusUpdateId: statusUpdateId,
          pumpId: pumpId,
          reportedBy: userId,
          reason: reason,
        );

    if (!mounted) return;

    if (success) {
      context.showAppSnackBar('Report submitted. Thanks for flagging this.');
      Navigator.of(context).pop();
    } else {
      final error = context.read<ReportViewModel>().errorMessage;
      context.showAppSnackBar(error ?? 'Could not submit report.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Report Wrong Update')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's wrong with this update?",
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ..._reasons.map(
              (reason) => RadioListTile<String>(
                value: reason,
                groupValue: _selectedReason,
                title: Text(reason),
                onChanged: (value) => setState(() => _selectedReason = value),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: viewModel.isSubmitting ? null : _submit,
                child: viewModel.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
