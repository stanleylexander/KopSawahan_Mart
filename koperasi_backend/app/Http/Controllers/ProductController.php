<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;

class ProductController extends Controller
{

    //TAMPILKAN SEMUA PRODUK
    public function index()
    {
        $products = Product::all();
        return response()->json($products);
    }

    //DETAIL PRODUK
    public function detail($id)
    {
        $product = Product::find($id);

        if(!$product){
            return response()->json([
                "message" => "Produk tidak ditemukan"
            ],404);
        }

        return response()->json($product);
    }

    //TAMBAH PRODUK
    public function store(Request $request)
    {

        $request->validate([
            'name' => 'required',
            'price' => 'required',
            'stock' => 'required',
            'image' => 'nullable|image|mimes:jpg,jpeg,png'
        ]);

        $imagePath = null;

        if($request->hasFile('image')){
            $imagePath = $request->file('image')
                        ->store('products','public');
        }

        $product = Product::create([
            'name' => $request->name,
            'price' => $request->price,
            'stock' => $request->stock,
            'description' => $request->description,
            'image' => $imagePath
        ]);

        return response()->json([
            "message" => "Produk berhasil ditambahkan",
            "data" => $product
        ]);
    }

    //UPDATE PRODUK
    public function update(Request $request, $id)
    {

        $product = Product::find($id);

        if(!$product){
            return response()->json([
                "message" => "Produk tidak ditemukan"
            ],404);
        }

        $product->update($request->all());

        return response()->json([
            "message" => "Produk berhasil diupdate",
            "data" => $product
        ]);

    }

    //DELETE PRODUK
    public function destroy($id)
    {

        $product = Product::find($id);

        if(!$product){
            return response()->json([
                "message" => "Produk tidak ditemukan"
            ],404);
        }

        $product->delete();

        return response()->json([
            "message" => "Produk berhasil dihapus"
        ]);

    }
}
