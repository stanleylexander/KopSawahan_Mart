import 'package:flutter/material.dart';

class MemberDrawer extends StatelessWidget {
  final Function(int) onTapMenu;
  final VoidCallback onLogout;
  final String name;
  final String email;

  const MemberDrawer({
    super.key,
    required this.onTapMenu,
    required this.onLogout,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: Text(email),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),

          _menuItem(Icons.person, "Profil", 0),
          _menuItem(Icons.store, "Belanja", 1),
          _menuItem(Icons.shopping_cart, "Keranjang", 2),
          _menuItem(Icons.card_giftcard, "Poin", 3),
          _menuItem(Icons.history, "History", 4),

          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onTapMenu(index),
    );
  }
}