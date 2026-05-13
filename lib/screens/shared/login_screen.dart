import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:microlab/theme/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final String userRole; // 'customer' or 'technician'

  const LoginScreen({super.key, required this.userRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _mobileFocus = FocusNode();
  bool _isValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_validate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_mobileFocus);
    });
  }

  void _validate() {
    final val = _mobileController.text.trim();
    setState(() {
      _isValid = val.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(val);
    });
  }

  Future<void> _sendOtp() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // TODO: Call API — POST /api/auth/send-otp { mobile: _mobileController.text }
    await Future.delayed(const Duration(milliseconds: 800)); // mock delay

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            mobile: _mobileController.text.trim(),
            userRole: widget.userRole,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.userRole == 'customer' || widget.userRole == 'vip_customer';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 28),

                // Logo
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.water_drop_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'MicroLab',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Text(
                  isCustomer
                      ? 'Enter your mobile number'
                      : 'Technician login',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isCustomer
                      ? "We'll send a 4-digit OTP to verify your number"
                      : "Enter your registered technician mobile number",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCustomer
                            ? Icons.person_outline
                            : Icons.medical_services_outlined,
                        size: 13,
                        color: AppColors.brandGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCustomer ? 'Customer' : 'Technician',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.brandGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Mobile field label
                const Text(
                  'Mobile number',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // Mobile input
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _mobileFocus.hasFocus
                          ? AppColors.brandGreen
                          : AppColors.divider,
                      width: _mobileFocus.hasFocus ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Country code prefix
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: const Border(
                            right: BorderSide(color: AppColors.divider),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🇮🇳',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Number input
                      Expanded(
                        child: TextField(
                          controller: _mobileController,
                          focusNode: _mobileFocus,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.0,
                          ),
                          decoration: const InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _sendOtp(),
                        ),
                      ),

                      // Clear / tick icon
                      if (_mobileController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _isValid
                              ? const Icon(Icons.check_circle_outline,
                                  color: AppColors.brandGreen, size: 20)
                              : GestureDetector(
                                  onTap: () => _mobileController.clear(),
                                  child: const Icon(Icons.cancel_outlined,
                                      color: AppColors.textHint, size: 20),
                                ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Validation hint
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _mobileController.text.isNotEmpty && !_isValid
                      ? const Row(
                          key: ValueKey('error'),
                          children: [
                            Icon(Icons.info_outline,
                                size: 12, color: Color(0xFFD32F2F)),
                            SizedBox(width: 4),
                            Text(
                              'Enter a valid 10-digit mobile number',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFD32F2F)),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('ok')),
                ),

                const SizedBox(height: 28),

                // Send OTP button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isValid && !_isLoading ? _sendOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      disabledBackgroundColor:
                          AppColors.brandGreen.withOpacity(0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Terms
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      children: [
                        TextSpan(text: 'By continuing you agree to our '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                              color: AppColors.brandGreen,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
