import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _secondsRemaining = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify(AuthViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    await viewModel.verifyOtp(_otpController.text);

    if (!mounted) return;

    if (viewModel.step == AuthStep.verified) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  Future<void> _handleResend(AuthViewModel viewModel) async {
    _otpController.clear();
    await viewModel.resendOtp();
    if (!mounted) return;
    _startResendTimer();
  }

  void _handleChangeNumber(AuthViewModel viewModel) {
    viewModel.changeNumber();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(AppIcons.back),
                    onPressed: () => _handleChangeNumber(viewModel),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.lock,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Verify Your Number',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'OTP sent to +91 ${viewModel.phoneNumber}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              Center(
                child: TextButton(
                  onPressed: () => _handleChangeNumber(viewModel),
                  child: const Text('Change Number'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                autoFocus: true,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor: theme.colorScheme.primary,
                  selectedColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.outline,
                ),
                onCompleted: (_) => _handleVerify(viewModel),
                onChanged: (_) {},
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: _secondsRemaining > 0
                    ? Text(
                        'Resend OTP in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      )
                    : TextButton(
                        onPressed:
                            viewModel.isLoading ? null : () => _handleResend(viewModel),
                        child: const Text('Resend OTP'),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: (viewModel.isLoading || _otpController.text.length != 6)
                    ? null
                    : () => _handleVerify(viewModel),
                child: viewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
