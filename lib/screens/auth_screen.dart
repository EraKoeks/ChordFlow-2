import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() =>
      _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  final _confirmPasswordController =
  TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_isLoading ||
        !(_formKey.currentState?.validate() ??
            false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRegistering) {
        await AuthService.register(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await AuthService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.errorMessage(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vul eerst een geldig e-mailadres in.',
          ),
        ),
      );
      return;
    }

    try {
      await AuthService.sendPasswordReset(
        email: email,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'De herstelmail is verzonden.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthService.errorMessage(error),
          ),
        ),
      );
    }
  }

  void _switchMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _formKey.currentState?.reset();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor:
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Icon(
                            Icons.library_music,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ChordFlow',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRegistering
                              ? 'Maak je account aan'
                              : 'Log in om verder te gaan',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller:
                          _emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          textInputAction:
                          TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          decoration:
                          const InputDecoration(
                            labelText: 'E-mailadres',
                            prefixIcon:
                            Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email =
                                value?.trim() ?? '';

                            if (email.isEmpty ||
                                !email.contains('@')) {
                              return 'Vul een geldig e-mailadres in';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller:
                          _passwordController,
                          obscureText: _hidePassword,
                          textInputAction:
                          _isRegistering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) {
                            if (!_isRegistering) {
                              _submit();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Wachtwoord',
                            prefixIcon:
                            const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _hidePassword =
                                  !_hidePassword;
                                });
                              },
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return 'Gebruik minimaal 6 tekens';
                            }

                            return null;
                          },
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:
                            _confirmPasswordController,
                            obscureText: _hidePassword,
                            textInputAction:
                            TextInputAction.done,
                            onFieldSubmitted: (_) {
                              _submit();
                            },
                            decoration:
                            const InputDecoration(
                              labelText:
                              'Wachtwoord herhalen',
                              prefixIcon:
                              Icon(Icons.lock_reset),
                            ),
                            validator: (value) {
                              if (value !=
                                  _passwordController.text) {
                                return 'De wachtwoorden zijn niet hetzelfde';
                              }

                              return null;
                            },
                          ),
                        ],
                        if (!_isRegistering) ...[
                          Align(
                            alignment:
                            Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                              _resetPassword,
                              child: const Text(
                                'Wachtwoord vergeten?',
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed:
                          _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : Icon(
                            _isRegistering
                                ? Icons.person_add_outlined
                                : Icons.login,
                          ),
                          label: Text(
                            _isLoading
                                ? 'Bezig...'
                                : _isRegistering
                                ? 'Account maken'
                                : 'Inloggen',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                          _isLoading ? null : _switchMode,
                          child: Text(
                            _isRegistering
                                ? 'Heb je al een account? Inloggen'
                                : 'Nog geen account? Account maken',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
