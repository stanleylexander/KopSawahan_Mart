import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../class/user.dart';
import '../../services/user_service.dart';
import '../drawer/drawer_admin.dart';

class UserAdminPage extends StatefulWidget {
  const UserAdminPage({super.key});

  @override
  State<UserAdminPage> createState() => _UserAdminPageState();
}

class _UserAdminPageState extends State<UserAdminPage> {

  late Future<List<User>> futureUsers;
  TextEditingController? _searchController;

  TextEditingController get searchController {
    _searchController ??= TextEditingController();
    return _searchController!;
  }

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    setState(() {
      futureUsers = UserService.getUsers(token);
    });
  }

  Future<void> refreshData() async {
    await loadUsers();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Manage Users",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Cari nama user...",
                prefixIcon: Icon(Icons.search, color: Colors.red.shade700),
                filled: true,
                fillColor: Colors.red.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.red.shade700,
              onRefresh: refreshData,
              child: buildUserList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= USER LIST =================
  Widget buildUserList() {
    return FutureBuilder<List<User>>(
      future: futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red.shade700),
                SizedBox(height: 16),
                Text(
                  "Memuat user...",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        final keyword = searchController.text.toLowerCase();
        final users = allUsers.where((user) {
          return user.name.toLowerCase().contains(keyword);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Tidak ada user",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  // ================= USER CARD =================
  Widget _buildUserCard(User user) {
    Color badgeColor;

    switch (user.role) {
      case 'admin':
        badgeColor = Colors.red.shade700;
        break;
      case 'cashier':
        badgeColor = Colors.orange.shade600;
        break;
      case 'worker':
        badgeColor = Colors.blue.shade600;
        break;
      default:
        badgeColor = Colors.green.shade600;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade50,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: badgeColor.withOpacity(0.15),
            child: Icon(
              Icons.person,
              color: badgeColor,
              size: 28,
            ),
          ),
          SizedBox(width: 16),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatRole(user.role),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ACTION
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            onPressed: () => showRoleDialog(context, user.id, user.role),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'cashier':
        return 'Kasir';
      case 'worker':
        return 'Anggota';
      default:
        return 'Member';
    }
  }

  // ================= DIALOG ROLE =================
  void showRoleDialog(BuildContext context, int userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = currentRole;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 20),

                    Text(
                      "Ubah Role User",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),

                    SizedBox(height: 24),

                    DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: "member", child: Text("Member")),
                        DropdownMenuItem(value: "worker", child: Text("Anggota")),
                        DropdownMenuItem(value: "cashier", child: Text("Kasir")),
                        DropdownMenuItem(value: "admin", child: Text("Admin")),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedRole = value!;
                        });
                      },
                    ),

                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Batal"),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              String token = prefs.getString('token') ?? '';

                              bool success = await UserService.updateUserRole(
                                userId,
                                selectedRole,
                                token,
                              );

                              Navigator.pop(context);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? "Role berhasil diubah"
                                          : "Gagal ubah role",
                                    ),
                                  ),
                                );
                                refreshData();
                              }
                            },
                            child: Text("Simpan"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
