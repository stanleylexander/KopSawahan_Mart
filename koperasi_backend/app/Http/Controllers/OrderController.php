<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

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
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        $order = DB::transaction(function () use ($request) {
            $total = 0;

            $order = Order::create([
                'user_id' => Auth::id(),
                'payment_method' => $request->payment_method,
                'status' => $request->status ?? 'pending',
                'total_price' => 0
            ]);

            foreach ($request->items as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $quantity = (int) $item['quantity'];

                if ($product->stock < $quantity) {
                    throw new HttpResponseException(response()->json([
                        'message' => "Stok produk {$product->name} tidak mencukupi"
                    ], 422));
                }

                $subtotal = $product->price * $quantity;
                $total += $subtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'price' => $product->price,
                ]);

                $product->decrement('stock', $quantity);
            }

            $order->update([
                'total_price' => $total
            ]);

            return $order->fresh();
        });

        return response()->json([
            'message' => 'Order berhasil dibuat',
            'order' => $order
        ]);
    }

    // DETAIL ORDER
    // public function show($id)
    // {
    //     $order = Order::with('items', 'user')->findOrFail($id);

    //     return response()->json($order);
    // }

    // UPDATE STATUS
    public function complete($id)
    {
        $order = Order::findOrFail($id);

        $order->status = 'selesai';
        $order->save();

        // KURANG NOTIFIKASI

        return response()->json([
            'message' => 'Pesanan selesai'
        ]);
    }
}
