import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../class/product.dart';
import '../../class/user.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import 'product_detail_admin.dart';
import 'add_product_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {

  String token = "";

  bool isProductView = true;

  late Future<List<Product>> futureProducts;
  late Future<List<User>> futureUsers;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';

    loadProducts();
    loadUsers();

    setState(() {});
  }

  void loadProducts() {
    futureProducts = ProductService.getProducts();
  }

  void loadUsers() {
    futureUsers = UserService.getUsers(token);
  }

  Future<void> refreshData() async {
    setState(() {
      loadProducts();
      loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Dashboard Admin",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // 🔥 TOGGLE BUTTON (Segmented Control)
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleBtn(
                  label: "Product",
                  icon: Icons.inventory_2_outlined,
                  isActive: isProductView,
                  onTap: () => setState(() => isProductView = true),
                ),
                SizedBox(width: 4),
                _buildToggleBtn(
                  label: "User",
                  icon: Icons.people_outline,
                  isActive: !isProductView,
                  onTap: () => setState(() => isProductView = false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🔥 CONTENT
          Expanded(
            child: RefreshIndicator(
              color: Colors.red.shade700,
              backgroundColor: Colors.white,
              onRefresh: refreshData,
              child: isProductView
                  ? buildProductList()
                  : buildUserList(),
            ),
          ),
        ],
      ),

      floatingActionButton: isProductView ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
        },
        backgroundColor: Colors.red.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildToggleBtn({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.red.shade700 : Colors.grey[200],
          foregroundColor: isActive ? Colors.white : Colors.grey[600],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PRODUCT LIST =================
  Widget buildProductList() {
    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red.shade700),
                SizedBox(height: 16),
                Text(
                  "Memuat produk...",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Tidak ada produk",
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
          itemCount: products.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailProductPage(product: product),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      ProductService.getImageUrl(product.image),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey[100],
                      child: Icon(Icons.image, color: Colors.grey[400]),
                    ),
            ),

            SizedBox(width: 16),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.price_change,
                          size: 16, color: Colors.red.shade700),
                      SizedBox(width: 4),
                      Text(
                        "Rp ${product.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.inventory_2,
                          size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        "Stok: ${product.stock}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Text(
                    product.description ?? "Tidak ada deskripsi",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 ACTION BUTTON (BARU)
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // TODO: EDIT PRODUCT
                    print("Edit product ${product.id}");
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: DELETE PRODUCT
                    showDeleteDialog(product.id);
                  },
                ),
              ],
            ),
          ],
        ),
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

        final users = snapshot.data ?? [];

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

  Widget _buildUserCard(User user) {
    // Warna badge berdasarkan role
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
                Row(
                  children: [
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
              ],
            ),
          ),
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICON
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

  // ================= DIALOG DELETE PRODUCT =================
  void showDeleteDialog(int productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hapus Produk"),
          content: Text("Apakah kamu yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                print("Delete product $productId");
              },
              child: Text("Hapus"),
            ),
          ],
        );
      },
    );
  }
}