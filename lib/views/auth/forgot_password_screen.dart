import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success =
        await viewModel.sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      _emailSent ? AppIcons.checkCircle : AppIcons.lock,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  _emailSent ? 'Check Your Email' : 'Reset Password',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _emailSent
                      ? 'We sent a password reset link to ${_emailController.text.trim()}'
                      : "Enter your email and we'll send you a link to reset your password",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (!_emailSent) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(AppIcons.email),
                    ),
                    validator: Validators.validateEmail,
                    onFieldSubmitted: (_) => _handleSendResetLink(viewModel),
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
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _handleSendResetLink(viewModel),
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Reset Link'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Back to Sign In'),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
