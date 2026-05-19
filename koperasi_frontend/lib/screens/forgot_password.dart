import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isOtpStep = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.red.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade200, width: 1.5),
      ),
    );
  }

  bool _validateEmail() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Email wajib diisi");
      return false;
    }

    if (!email.contains("@")) {
      _showMessage("Format email belum benar");
      return false;
    }

    return true;
  }

  bool _validateResetForm() {
    if (otpController.text.trim().length != 6) {
      _showMessage("Masukkan 6 digit kode OTP");
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      _showMessage("Password baru minimal 6 karakter");
      return false;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showMessage("Konfirmasi password tidak sama");
      return false;
    }

    return true;
  }

  Future<void> requestOtp() async {
    if (!_validateEmail()) {
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.requestForgotPasswordOtp(
      emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
      if (result["success"] == true) {
        isOtpStep = true;
      }
    });

    _showMessage(result["message"]);
  }

  Future<void> resetPassword() async {
    if (!_validateResetForm()) {
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.resetPasswordWithOtp(
      emailController.text.trim(),
      otpController.text.trim(),
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => isLoading = false);
    _showMessage(result["message"]);

    if (result["success"] == true) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Lupa Password",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.red.shade700,
                    child: Icon(
                      isOtpStep ? Icons.lock_reset : Icons.mark_email_unread,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOtpStep ? "Reset Password" : "Verifikasi Email",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpStep
                        ? "Masukkan kode OTP dan password baru kamu"
                        : "Masukkan email akun kamu untuk menerima kode OTP",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    readOnly: isOtpStep,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInputDecoration(
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                  ),
                  if (isOtpStep) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: _buildInputDecoration(
                        label: "Kode OTP",
                        icon: Icons.verified_user_outlined,
                      ).copyWith(
                        helperText: "Kode berlaku selama 10 menit",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration(
                        label: "Password Baru",
                        icon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: _buildInputDecoration(
                        label: "Konfirmasi Password",
                        icon: Icons.lock_reset,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : requestOtp,
                        child: Text(
                          "Kirim ulang OTP",
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: isOtpStep ? resetPassword : requestOtp,
                            child: Text(
                              isOtpStep ? "Ubah Password" : "Kirim OTP",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
