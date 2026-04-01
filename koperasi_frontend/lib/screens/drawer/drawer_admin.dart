import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/home_admin.dart';
import '../admin/user_admin.dart';
import '../admin/voucher_admin.dart';
import '../profile_page.dart';
import '../login.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Login()),
      (route) => false,
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.shade700),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [

          // 🔥 HEADER
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade700, Colors.red.shade500],
              ),
            ),
            accountName: Text("Admin"),
            accountEmail: Text("admin@email.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.red.shade700),
            ),
          ),

          // 🔥 MENU
          buildMenuItem(
            icon: Icons.person,
            title: "Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            },
          ),

          buildMenuItem(
            icon: Icons.inventory,
            title: "Product",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeAdmin()),
              );
            },
          ),

          buildMenuItem(
            icon: Icons.people,
            title: "User",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserAdminPage()),
              );
            },
          ),

          buildMenuItem(
            icon: Icons.card_giftcard,
            title: "Voucher",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VoucherAdminPage()),
              );
            },
          ),

          Spacer(),

          Divider(),

          buildMenuItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}