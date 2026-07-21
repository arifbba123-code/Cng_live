import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/pump_model.dart';
import '../../data/models/status_update_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/status_viewmodel.dart';
import '../widgets/status_badge.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({super.key});

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  String? _pumpId;
  PumpStatus? _selectedStatus;
  final _queueMinutesController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _pumpId = args;
      }
      _didInit = true;
    }
  }

  @override
  void dispose() {
    _queueMinutesController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(
    StatusViewModel statusViewModel,
    AuthViewModel authViewModel,
  ) async {
    if (_pumpId == null || _selectedStatus == null) return;

    final user = authViewModel.user;

    final update = StatusUpdateModel(
      id: '',
      pumpId: _pumpId!,
      userId: user?.id ?? '',
      userName: user?.name,
      status: _selectedStatus!,
      queueLength: _selectedStatus == PumpStatus.longQueue
          ? _queueMinutesController.text.trim()
          : null,
      photo: null,
      timestamp: DateTime.now(),
    );

    await statusViewModel.submitStatusUpdate(update);

    if (!mounted) return;

    if (statusViewModel.isSuccess) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColors = context.statusColors;
    final statusViewModel = context.watch<StatusViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Update Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "What's the status right now?",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusOption(
              label: PumpStatus.stockAvailable.label,
              color: statusColors.stockAvailable,
              selected: _selectedStatus == PumpStatus.stockAvailable,
              onTap: () => setState(
                  () => _selectedStatus = PumpStatus.stockAvailable),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: PumpStatus.longQueue.label,
              color: statusColors.longQueue,
              selected: _selectedStatus == PumpStatus.longQueue,
              onTap: () =>
                  setState(() => _selectedStatus = PumpStatus.longQueue),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: PumpStatus.noStock.label,
              color: statusColors.noStock,
              selected: _selectedStatus == PumpStatus.noStock,
              onTap: () =>
                  setState(() => _selectedStatus = PumpStatus.noStock),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StatusOption(
              label: PumpStatus.unverified.label,
              color: statusColors.unverified,
              selected: _selectedStatus == PumpStatus.unverified,
              onTap: () =>
                  setState(() => _selectedStatus = PumpStatus.unverified),
            ),
            if (_selectedStatus == PumpStatus.longQueue) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Queue Time (minutes)', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _queueMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 15'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Remarks (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'e.g. Only CNG lane open'),
            ),
            if (statusViewModel.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                statusViewModel.errorMessage!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
            ElevatedButton(
              onPressed: (_selectedStatus == null || statusViewModel.isLoading)
                  ? null
                  : () => _handleSubmit(statusViewModel, authViewModel),
              child: statusViewModel.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
