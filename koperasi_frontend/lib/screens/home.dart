import 'package:flutter/material.dart';
import '../class/product.dart';
import '../services/product_service.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<Product> products = [];
  List<Product> filteredProducts = [];

  bool isLoading = true;

  TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  void fetchProducts() async {

    List<Product> data =
        await ProductService.getProducts();

    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });

  }

  void searchProduct(String keyword){

    final results = products.where((product) {

      final name = product.name.toLowerCase();

      final search = keyword.toLowerCase();

      return name.contains(search);

    }).toList();

    setState(() {
      filteredProducts = results;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Koperasi Mart"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(

              controller: searchController,

              onChanged: searchProduct,

              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                )
              ),

            ),
          ),

          // LIST PRODUCT
          Expanded(

            child: isLoading
                ? Center(child: CircularProgressIndicator())

                : GridView.builder(

                    padding: EdgeInsets.symmetric(horizontal: 10),

                    itemCount: filteredProducts.length,

                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(

                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75

                    ),

                    itemBuilder: (context, index) {

                      final product = filteredProducts[index];

                      return productCard(product);

                    },

                  ),
          ),

        ],
      ),
    );
  }

  Widget productCard(Product product){

    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: Offset(0,3)
          )
        ]
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // IMAGE
          Expanded(

            child: ClipRRect(

              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(15)),

              child: product.image != null
                  ? Image.network(
                      "http://192.168.1.10:8000/storage/${product.image}",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image,size: 50),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 4),

                Text(
                  "Rp ${product.price}",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  "Stok: ${product.stock}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey
                  ),
                )

              ],
            ),
          )

        ],
      ),
    );

  }

}