<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['user', 'items.product'])
            ->where('status', 'pending')
            ->get();

        return response()->json($orders);
    }

    public function store(Request $request)
    {
        $request->validate([
            'payment_method' => 'required|in:cash,online',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        $order = DB::transaction(function () use ($request) {
            $totalPrice = 0;

            $order = Order::create([
                'user_id' => Auth::id(),
                'payment_method' => $request->payment_method,
                'status' => $request->status ?? 'pending',
                'total_price' => 0,
            ]);

            foreach ($request->items as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $quantity = (int) $item['quantity'];

                if ($product->stock < $quantity) {
                    throw new HttpResponseException(response()->json([
                        'message' => "Stok produk {$product->name} tidak cukup",
                    ], 422));
                }

                $subtotal = $product->price * $quantity;
                $totalPrice += $subtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'price' => $product->price,
                ]);

                $product->decrement('stock', $quantity);
            }

            $order->update([
                'total_price' => $totalPrice,
            ]);

            Notification::create([
                'user_id' => $order->user_id,
                'order_id' => $order->id,
                'title' => 'Checkout berhasil',
                'message' => 'Pesanan kamu sudah masuk dan sedang diproses.',
                'type' => 'checkout',
            ]);

            return $order->fresh();
        });

        return response()->json([
            'message' => 'Order berhasil dibuat',
            'order' => $order,
        ]);
    }

    public function complete($id)
    {
        $order = Order::findOrFail($id);

        $order->status = 'selesai';
        $order->save();

        Notification::create([
            'user_id' => $order->user_id,
            'order_id' => $order->id,
            'title' => 'Pesanan siap diambil',
            'message' => 'Pesanan kamu sudah siap diambil di koperasi.',
            'type' => 'pickup',
        ]);

        return response()->json([
            'message' => 'Pesanan selesai',
        ]);
    }
}
