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
}
