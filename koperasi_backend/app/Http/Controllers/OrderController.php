<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Support\Facades\Auth;

class OrderController extends Controller
{
    
    public function index()
    {
        $orders = Order::with(['user', 'items.product'])->where('status', 'pending')->get();
        return response()->json($orders);
    }

    // CREATE ORDER
    public function store(Request $request)
    {
        $request->validate([
            'payment_method' => 'required|in:cash,online',
            'items' => 'required|array'
        ]);

        $total = 0;

        // 🔥 Buat order dulu
        $order = Order::create([
            'user_id' => Auth::id(),
            'payment_method' => $request->payment_method,
            'status' => 'pending',
            'total_price' => 0
        ]);

        foreach ($request->items as $item) {

            $product = Product::findOrFail($item['product_id']);

            $subtotal = $product->price * $item['quantity'];
            $total += $subtotal;

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_name' => $product->name,
                'quantity' => $item['quantity'],
                'price' => $product->price,
            ]);
        }

        // ✅ Update total setelah loop
        $order->update([
            'total_price' => $total
        ]);

        return response()->json([
            'message' => 'Order berhasil dibuat',
            'order' => $order
        ]);
    }

    // DETAIL ORDER
    public function show($id)
    {
        $order = Order::with('items', 'user')->findOrFail($id);

        return response()->json($order);
    }

    // UPDATE STATUS
    public function complete($id)
    {
        $order = Order::findOrFail($id);

        $order->status = 'completed';
        $order->save();

        // KURANG NOTIFIKASI

        return response()->json([
            'message' => 'Pesanan selesai'
        ]);
    }
}