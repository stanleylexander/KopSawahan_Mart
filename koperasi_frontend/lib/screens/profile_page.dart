import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../class/user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<User?> futureUser;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    setState(() {
      futureUser = UserService.getProfile(token);
    });
  }

  Future<void> handleLogout() async {
    await AuthService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
      ),

      body: FutureBuilder<User?>(
        future: futureUser,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text("Gagal memuat profile"),
            );
          }

          final user = snapshot.data!;

          return RefreshIndicator(
            onRefresh: loadProfile,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [

                  // 🔥 HEADER
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade700, Colors.red.shade500],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 12),

                        Text(
                          user.name ?? "-",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          user.email ?? "-",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // 🔥 INFO CARD
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow("Nama", user.name),
                        _buildInfoRow("Email", user.email),
                        _buildInfoRow("No HP", user.phoneNumber),
                        _buildInfoRow("Tanggal Lahir", user.dateOfBirth),
                        _buildInfoRow("Gender", _formatGender(user.gender)),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // 🔥 LOGOUT BUTTON
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: handleLogout,
                      icon: Icon(Icons.logout),
                      label: Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= HELPER =================

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value ?? "-",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == "male") return "Laki-laki";
    if (gender == "female") return "Perempuan";
    return "-";
  }
}