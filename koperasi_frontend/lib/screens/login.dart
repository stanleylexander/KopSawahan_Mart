import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'member/home.dart';
import 'register.dart';
import 'admin/home_admin.dart';
import 'cashier/home_cashier.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    setState(() => isLoading = true);

    bool success = await AuthService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (success) {

      String? role = await AuthService.getRole();

      if (role == 'member') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home()),
        );
      } 
      else if (role == 'worker') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home()), 
        );
      }
      else if (role == 'cashier') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeCashier()),
        );
      }
      else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeAdmin()),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login gagal. Periksa email atau password.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Putih lembut sebagai dasar
      backgroundColor: Colors.white,
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
                      Icons.account_circle,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Login Koperasi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.red.shade700),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.red.shade700, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.red.shade200, width: 1.5),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline,
                          color: Colors.red.shade700),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.red.shade700, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.red.shade200, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: login,
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Lupa password?",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Register())
                      );
                    },
                    child: Text("Belum punya akun? Register")
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
