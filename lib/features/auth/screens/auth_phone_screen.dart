import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/domain/failure.dart';
import '../../../shared/theme/app_colors.dart';
import '../repository/auth_repository.dart';

class AuthPhoneScreen extends ConsumerStatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  ConsumerState<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends ConsumerState<AuthPhoneScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  static final _e164Regex = RegExp(r'^\+[1-9]\d{6,14}$');

  bool get _isValid => _e164Regex.hasMatch(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_isValid || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final failure =
        await ref.read(authRepositoryProvider).sendOtp(_controller.text.trim());

    if (!mounted) return;

    if (failure == null) {
      context.push('/auth/otp', extra: _controller.text.trim());
    } else {
      setState(() {
        _errorMessage =
            failure is NetworkFailure ? failure.message : failure.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = _isValid;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              Text(
                'GestBud',
                style: GoogleFonts.urbanist(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gérez votre budget\nen toute simplicité.',
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Ton numéro de téléphone',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.phone,
                style: GoogleFonts.urbanist(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: '+225 07 XX XX XX XX',
                  hintStyle: GoogleFonts.urbanist(color: AppColors.textDisabled),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (valid && !_isLoading) ? _sendOtp : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Envoyer le code',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
