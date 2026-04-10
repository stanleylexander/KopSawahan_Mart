import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import '../cashier/home_cashier.dart';

class CashierDrawer extends StatelessWidget {
  const CashierDrawer({super.key});

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
        style: const TextStyle(fontWeight: FontWeight.w600),
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
            accountName: const Text("Cashier"),
            accountEmail: const Text("cashier@email.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.red.shade700),
            ),
          ),

          // 🏠 HOME (Pesanan)
          buildMenuItem(
            icon: Icons.receipt_long,
            title: "Pesanan",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeCashier()),
              );
            },
          ),

          // 🛒 BELANJA 
          buildMenuItem(
            icon: Icons.shopping_cart,
            title: "Belanja",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeCashier()),
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