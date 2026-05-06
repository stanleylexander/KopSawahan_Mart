import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'drawer/navbar.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final birthController = TextEditingController();
  final otpController = TextEditingController();

  String gender = "Male";
  bool isLoading = false;
  bool isOtpStep = false;
  DateTime? selectedDate;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _validateRegisterForm() {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        birthController.text.trim().isEmpty) {
      _showMessage("Semua data register wajib diisi");
      return false;
    }

    if (!emailController.text.trim().contains("@")) {
      _showMessage("Format email belum benar");
      return false;
    }

    if (passwordController.text.trim().length < 6) {
      _showMessage("Password minimal 6 karakter");
      return false;
    }

    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        birthController.text = _formatDate(picked);
      });
    }
  }

  Future<void> requestOtp() async {
    if (!_validateRegisterForm()) {
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.requestRegisterOtp(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
      phoneController.text.trim(),
      birthController.text.trim(),
      gender,
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

  Future<void> verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      _showMessage("Masukkan 6 digit kode OTP");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.verifyRegisterOtp(
      emailController.text.trim(),
      otpController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => isLoading = false);

    _showMessage(result["message"]);

    if (result["success"] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Navbar()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    birthController.dispose();
    otpController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.red.shade700),
      suffixIcon: suffixIcon,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Register Koperasi",
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
                      isOtpStep ? Icons.mark_email_read : Icons.person_add,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOtpStep ? "Verifikasi OTP" : "Daftar Akun Baru",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOtpStep
                        ? "Masukkan 6 digit kode OTP yang dikirim ke email kamu"
                        : "Isi data dulu, lalu kami kirim kode OTP ke email",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!isOtpStep) ...[
                    TextField(
                      controller: nameController,
                      decoration: buildInputDecoration(
                        label: "Nama Lengkap",
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: buildInputDecoration(
                        label: "Email",
                        icon: Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: buildInputDecoration(
                        label: "Password",
                        icon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: buildInputDecoration(
                        label: "Nomor HP",
                        icon: Icons.phone_outlined,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: birthController,
                      readOnly: true,
                      decoration: buildInputDecoration(
                        label: "Tanggal Lahir (YYYY-MM-DD)",
                        icon: Icons.calendar_today_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.date_range, color: Colors.red.shade700),
                          onPressed: _selectDate,
                        ),
                      ),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: buildInputDecoration(
                        label: "Gender",
                        icon: Icons.wc_outlined,
                      ),
                      items: ["Male", "Female"].map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(g),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          gender = value.toString();
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: emailController,
                      readOnly: true,
                      decoration: buildInputDecoration(
                        label: "Email",
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: buildInputDecoration(
                        label: "Kode OTP",
                        icon: Icons.verified_user_outlined,
                      ).copyWith(
                        helperText: "Kode berlaku selama 10 menit",
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
                            onPressed: isOtpStep ? verifyOtp : requestOtp,
                            child: Text(
                              isOtpStep ? "Verifikasi OTP" : "Kirim OTP",
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
