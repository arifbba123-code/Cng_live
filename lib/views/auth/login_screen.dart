import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  void _goToRegister() {
    context.read<AuthViewModel>().clearError();
    Navigator.of(context).pushNamed('/register');
  }

  void _goToForgotPassword() {
    context.read<AuthViewModel>().clearError();
    Navigator.of(context).pushNamed('/forgot-password');
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.pump,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: Icon(AppIcons.email),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(AppIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? AppIcons.visibilityOff
                            : AppIcons.visibilityOn,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: Validators.validatePassword,
                  onFieldSubmitted: (_) => _handleLogin(viewModel),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _goToForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed:
                      viewModel.isLoading ? null : () => _handleLogin(viewModel),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
