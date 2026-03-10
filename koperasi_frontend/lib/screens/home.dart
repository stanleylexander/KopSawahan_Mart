import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login.dart';

class Home extends StatelessWidget {

  void logout(BuildContext context) async {

    await AuthService.logout();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Login(),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Home"),
        actions: [

          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout),
          )

        ],
      ),

      body: Center(
        child: Text(
          "Login Berhasil",
          style: TextStyle(fontSize: 24),
        ),
      ),

    );

  }

}