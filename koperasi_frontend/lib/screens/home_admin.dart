import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/product.dart';
import '../class/user.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import 'product_detail_admin.dart';

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
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          // 🔥 TOGGLE BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isProductView = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isProductView ? Colors.blue : Colors.grey,
                ),
                child: const Text("Product"),
              ),

              const SizedBox(width: 10),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isProductView = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      !isProductView ? Colors.blue : Colors.grey,
                ),
                child: const Text("User"),
              ),

            ],
          ),

          const SizedBox(height: 10),

          // 🔥 CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshData,
              child: isProductView
                  ? buildProductList()
                  : buildUserList(),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRODUCT LIST =================
  Widget buildProductList() {
    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(child: Text("Tidak ada produk"));
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {

            final product = products[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DetailProductPage(product: product),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 4,
                      color: Colors.black12,
                      offset: Offset(0, 2),
                    )
                  ],
                ),

                child: Row(
                  children: [

                    // IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.image != null &&
                              product.image!.isNotEmpty
                          ? Image.network(
                              ProductService.getImageUrl(product.image),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text("Harga: Rp ${product.price}"),
                          Text("Stok: ${product.stock}"),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

  // ================= USER LIST =================
  Widget buildUserList() {
    return FutureBuilder<List<User>>(
      future: futureUsers,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text("Tidak ada user"));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {

            final user = users[index];

            return ListTile(
              title: Text(user.name),
              subtitle: Text("Role: ${user.role}"),

              trailing: IconButton(
                icon: const Icon(Icons.admin_panel_settings,
                    color: Colors.green),
                onPressed: () {
                  showRoleDialog(context, user.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  // ================= DIALOG ROLE =================
  void showRoleDialog(BuildContext context, int userId) {
    String selectedRole = "member";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ubah Role User"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "member", child: Text("Member")),
                  DropdownMenuItem(value: "worker", child: Text("Anggota")),
                  DropdownMenuItem(value: "cashier", child: Text("Kasir")),
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              );
            },
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () async {

                final prefs = await SharedPreferences.getInstance();
                String token = prefs.getString('token') ?? '';

                bool success = await UserService.updateUserRole(
                  userId,
                  selectedRole,
                  token, 
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Role berhasil diubah"
                        : "Gagal ubah role"),
                  ),
                );

                refreshData();
              },
              child: const Text("Simpan"),
            ),

          ],
        );
      },
    );
  }
}