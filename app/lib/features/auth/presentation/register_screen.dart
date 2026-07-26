import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/strings/app_strings.dart';
import '../providers/auth_controller.dart';
import 'widgets/auth_text_field.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _emailRegex.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _confirmPasswordController.text == _passwordController.text;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _fieldErrors = const {};
    });

    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );
      // Success navigates via the router's redirect reacting to the new
      // auth state — no manual context.go here.
    } on ApiException catch (e) {
      if (!mounted) return;
      // A duplicate-email 409 has no `errors` array (that's only populated
      // for 400 validation failures) — map it onto the email field by hand.
      final fieldErrors = Map<String, String>.from(e.fieldErrors);
      if (e.isConflict) {
        fieldErrors['email'] = AppStrings.emailAlreadyRegistered;
      }
      setState(() => _fieldErrors = fieldErrors);
      if (!e.isConflict && fieldErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.registerTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _nameController,
                    label: AppStrings.nameLabel,
                    textInputAction: TextInputAction.next,
                    errorText: _fieldErrors['name'],
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) return AppStrings.nameRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _emailController,
                    label: AppStrings.emailLabel,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _fieldErrors['email'],
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return AppStrings.emailRequired;
                      if (!_emailRegex.hasMatch(v)) return AppStrings.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _passwordController,
                    label: AppStrings.passwordLabel,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    errorText: _fieldErrors['password'],
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return AppStrings.passwordRequired;
                      if (v.length < 8) return AppStrings.passwordTooShort;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: AppStrings.confirmPasswordLabel,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return AppStrings.passwordsDontMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isFormValid && !_isSubmitting ? _submit : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.registerButton),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : () => context.go('/login'),
                    child: const Text(AppStrings.hasAccountPrompt),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
