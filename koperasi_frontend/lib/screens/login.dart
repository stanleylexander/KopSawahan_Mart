import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home.dart';

class Login extends StatefulWidget {

  @override
  State<Login> createState() => _LoginState();

}

class _LoginState extends State<Login> {

  TextEditingController emailController =
  TextEditingController();

  TextEditingController passwordController =
  TextEditingController();

  bool isLoading = false;


  void login() async {

    setState(() {
      isLoading = true;
    });

    bool success =
    await AuthService.login(
        emailController.text,
        passwordController.text
    );

    setState(() {
      isLoading = false;
    });

    if (success) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Home(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login gagal"),
        ),
      );

    }

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Login Koperasi"),
      ),

      body: Padding(

        padding: EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(

              controller: emailController,

              decoration: InputDecoration(
                labelText: "Email",
              ),

            ),

            SizedBox(height: 10),

            TextField(

              controller: passwordController,

              obscureText: true,

              decoration: InputDecoration(
                labelText: "Password",
              ),

            ),

            SizedBox(height: 20),

            isLoading

                ? CircularProgressIndicator()

                : ElevatedButton(

              onPressed: login,

              child: Text("Login"),

            )

          ],

        ),

      ),

    );

  }

}