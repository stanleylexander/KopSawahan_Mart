<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Product;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;


class ProductController extends Controller
{

    // TAMPILKAN SEMUA PRODUK
    public function index()
    {
        $products = Product::all();
        return response()->json($products);
    }
    

    // DETAIL PRODUK
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


    // TAMBAH PRODUK
    public function store(Request $request)
    {
        try {

            $request->validate([
                'name' => 'required',
                'price' => 'required|numeric',
                'stock' => 'required|integer',
                'image' => 'nullable|image|mimes:jpg,jpeg,png'
            ]);

            $imagePath = null;

            if ($request->hasFile('image')) {
                $imagePath = $request->file('image')->store('products', 'public');
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

        } catch (\Exception $e) {
            return response()->json([
                "error" => $e->getMessage()
            ], 500);
        }
    }


    // UPDATE PRODUK
    public function update(Request $request, $id)
    {

        try {

            $product = Product::find($id);

            if (!$product) {
                return response()->json([
                    "message" => "Produk tidak ditemukan"
                ], 404);
            }

        } catch (\Exception $e) {
            return response()->json([
                "error" => $e->getMessage()
            ], 500);
        }

        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                "message" => "Produk tidak ditemukan"
            ], 404);
        }

        $request->validate([
            'name' => 'sometimes|required',
            'price' => 'sometimes|required|numeric',
            'stock' => 'sometimes|required|integer',
            'image' => 'nullable|image|mimes:jpg,jpeg,png'
        ]);

        // UPDATE IMAGE
        if ($request->hasFile('image')) {

            // HAPUS GAMBAR LAMA
            if ($product->image) {
                Storage::disk('public')->delete($product->image);
            }

            $imagePath = $request->file('image')
                ->store('products', 'public');

            $product->image = $imagePath;
        }

        $product->update([
            'name' => $request->name ?? $product->name,
            'price' => $request->price ?? $product->price,
            'stock' => $request->stock ?? $product->stock,
            'description' => $request->description ?? $product->description,
        ]);

        return response()->json([
            "message" => "Produk berhasil diupdate",
            "data" => $product
        ]);
    }


    // DELETE PRODUK
    public function destroy($id)
    {
        $product = Product::find($id);

        if (!$product) {
            return response()->json([
                "message" => "Produk tidak ditemukan"
            ], 404);
        }

        // HAPUS GAMBAR
        if ($product->image) {
            Storage::disk('public')->delete($product->image);
        }

        $product->delete();

        return response()->json([
            "message" => "Produk berhasil dihapus"
        ]);
    }
}
