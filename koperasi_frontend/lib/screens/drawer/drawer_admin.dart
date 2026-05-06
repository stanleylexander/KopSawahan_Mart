import 'package:flutter/material.dart';
import '../admin/home_admin.dart';
import '../admin/report_admin.dart';
import '../admin/user_admin.dart';
import '../admin/voucher_admin.dart';
import '../profile_page.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

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
            title: "Produk",
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

          buildMenuItem(
            icon: Icons.bar_chart,
            title: "Laporan",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportAdminPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
