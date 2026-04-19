<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\Receipt;
use App\Models\User;
use App\Models\UserVoucher;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index()
    {
        $orders = Order::with(['user', 'items.product', 'receipt'])
            ->whereIn('status', ['pending', 'selesai'])
            ->latest()
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
            'user_voucher_id' => 'nullable|integer|exists:user_vouchers,id',
            'order_source' => 'nullable|in:app,offline',
            'amount_paid' => 'nullable|integer|min:0',
        ]);

        $actor = $request->user();
        $orderSource = $request->input('order_source', 'app');
        $isOfflineOrder = $actor->isCashier() && $orderSource === 'offline';

        if ($orderSource === 'offline' && !$actor->isCashier()) {
            abort(403, 'Hanya kasir yang bisa membuat order offline');
        }

        $result = DB::transaction(function () use ($request, $actor, $isOfflineOrder, $orderSource) {
            $subtotalPrice = 0;
            $customer = $isOfflineOrder
                ? null
                : User::lockForUpdate()->findOrFail($actor->id);

            $customerName = $customer?->name;

            $order = Order::create([
                'user_id' => $customer?->id,
                'user_voucher_id' => null,
                'order_source' => $orderSource,
                'customer_name' => $customerName,
                'payment_method' => $request->payment_method,
                'status' => $request->status ?? 'pending',
                'total_price' => 0,
                'discount_amount' => 0,
            ]);

            foreach ($request->items as $item) {
                $product = Product::lockForUpdate()->findOrFail($item['product_id']);
                $quantity = (int) $item['quantity'];

                if ($product->stock < $quantity) {
                    throw new HttpResponseException(response()->json([
                        'message' => "Stok produk {$product->name} tidak cukup",
                    ], 422));
                }

                $itemSubtotal = $product->price * $quantity;
                $subtotalPrice += $itemSubtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'quantity' => $quantity,
                    'price' => $product->price,
                ]);

                $product->decrement('stock', $quantity);
            }

            $workerDiscountAmount = !$isOfflineOrder && $customer?->isWorker()
                ? (int) floor($subtotalPrice * 10 / 100)
                : 0;

            $priceAfterWorkerDiscount = $subtotalPrice - $workerDiscountAmount;
            $voucherDiscountAmount = 0;
            $userVoucherId = null;

            if (!$isOfflineOrder && $request->filled('user_voucher_id')) {
                $userVoucher = UserVoucher::with('voucher')
                    ->where('id', $request->user_voucher_id)
                    ->where('user_id', $customer->id)
                    ->where('status', 'unused')
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($userVoucher->expires_at && $userVoucher->expires_at->isPast()) {
                    $userVoucher->update([
                        'status' => 'used',
                    ]);

                    throw new HttpResponseException(response()->json([
                        'message' => 'Voucher sudah expired',
                    ], 422));
                }

                $voucher = $userVoucher->voucher;

                if ($priceAfterWorkerDiscount < $voucher->minimum_purchase_amount) {
                    throw new HttpResponseException(response()->json([
                        'message' => 'Minimal belanja untuk voucher ini adalah Rp ' . number_format($voucher->minimum_purchase_amount, 0, ',', '.'),
                    ], 422));
                }

                $discountPercent = $voucher->discount_amount;
                $voucherDiscountAmount = (int) floor($priceAfterWorkerDiscount * $discountPercent / 100);

                if ($voucher->max_discount_amount > 0) {
                    $voucherDiscountAmount = min($voucherDiscountAmount, $voucher->max_discount_amount);
                }

                $voucherDiscountAmount = min($voucherDiscountAmount, $priceAfterWorkerDiscount);
                $userVoucherId = $userVoucher->id;

                $userVoucher->update([
                    'status' => 'used',
                ]);
            }

            $discountAmount = $workerDiscountAmount + $voucherDiscountAmount;
            $finalTotalPrice = $subtotalPrice - $discountAmount;
            $amountPaid = null;
            $changeAmount = 0;

            if ($isOfflineOrder && $request->payment_method === 'cash') {
                $amountPaid = (int) $request->input('amount_paid', 0);

                if ($amountPaid < $finalTotalPrice) {
                    throw new HttpResponseException(response()->json([
                        'message' => 'Uang yang diberikan customer kurang',
                    ], 422));
                }

                $changeAmount = $amountPaid - $finalTotalPrice;
            }

            $order->update([
                'user_voucher_id' => $userVoucherId,
                'total_price' => $finalTotalPrice,
                'discount_amount' => $discountAmount,
            ]);

            if ($customer) {
                Notification::create([
                    'user_id' => $order->user_id,
                    'order_id' => $order->id,
                    'title' => 'Checkout berhasil',
                    'message' => 'Pesanan kamu sudah masuk dan sedang diproses.',
                    'type' => 'checkout',
                ]);
            }

            $receipt = null;

            if ($isOfflineOrder) {
                $receipt = $this->createReceipt(
                    $order->fresh(['items.product', 'user', 'userVoucher.voucher']),
                    'print',
                    'pending',
                    $actor->name,
                    $amountPaid,
                    $changeAmount
                );
            } elseif ($request->payment_method === 'online') {
                $receipt = $this->createReceipt(
                    $order->fresh(['items.product', 'user', 'userVoucher.voucher']),
                    'digital',
                    'not_needed'
                );
            }

            return [
                'order' => $order->fresh(['items.product', 'receipt']),
                'receipt' => $receipt,
            ];
        });

        return response()->json([
            'message' => 'Order berhasil dibuat',
            'order' => $result['order'],
            'receipt' => $result['receipt'],
        ]);
    }

    public function complete(Request $request, $id)
    {
        $result = DB::transaction(function () use ($id, $request) {
            $order = Order::with(['user', 'items.product', 'receipt', 'userVoucher.voucher'])
                ->lockForUpdate()
                ->findOrFail($id);

            $order->update([
                'status' => 'selesai',
            ]);

            if ($order->user_id) {
                Notification::create([
                    'user_id' => $order->user_id,
                    'order_id' => $order->id,
                    'title' => 'Pesanan siap diambil',
                    'message' => 'Pesanan kamu sudah siap diambil di koperasi.',
                    'type' => 'pickup',
                ]);
            }

            $receipt = $order->receipt;

            if ($order->payment_method === 'cash' && $order->order_source === 'app') {
                $receipt = $this->createReceipt(
                    $order->fresh(['items.product', 'user', 'userVoucher.voucher']),
                    'digital',
                    'not_needed',
                    $request->user()->name
                );
            } elseif ($receipt) {
                $receipt->update([
                    'cashier_name' => $request->user()->name,
                ]);
                $receipt = $receipt->fresh(['order.items', 'order.user']);
            }

            return [
                'order' => $order->fresh(['items.product', 'receipt']),
                'receipt' => $receipt,
            ];
        });

        return response()->json([
            'message' => 'Pesanan selesai',
            'order' => $result['order'],
            'receipt' => $result['receipt'],
        ]);
    }

    public function markAsTaken($id)
    {
        DB::transaction(function () use ($id) {
            $order = Order::lockForUpdate()->findOrFail($id);

            $order->update([
                'status' => 'diambil',
            ]);

            if (!$order->user_id) {
                return;
            }

            $user = User::lockForUpdate()->findOrFail($order->user_id);
            $earnedPoints = intdiv($order->total_price, 100);

            if ($earnedPoints > 0) {
                $user->increment('points', $earnedPoints);

                Notification::create([
                    'user_id' => $order->user_id,
                    'order_id' => $order->id,
                    'title' => 'Poin bertambah',
                    'message' => "Kamu mendapat {$earnedPoints} poin dari pesanan yang sudah diambil.",
                    'type' => 'point',
                ]);
            }
        });

        return response()->json([
            'message' => 'Pesanan sudah diambil',
        ]);
    }

    private function createReceipt(
        Order $order,
        string $receiptType,
        string $printStatus,
        ?string $cashierName = null,
        ?int $amountPaid = null,
        int $changeAmount = 0
    ): Receipt {
        $subtotalPrice = $order->items->sum(function ($item) {
            return $item->price * $item->quantity;
        });

        $workerDiscountAmount = $order->order_source === 'app' && $order->user?->isWorker()
            ? (int) floor($subtotalPrice * 10 / 100)
            : 0;

        $voucherDiscountAmount = max($order->discount_amount - $workerDiscountAmount, 0);
        $itemCount = $order->items->sum('quantity');

        $receipt = Receipt::updateOrCreate(
            ['order_id' => $order->id],
            [
                'receipt_number' => $this->buildReceiptNumber($order->id),
                'receipt_type' => $receiptType,
                'print_status' => $printStatus,
                'customer_name' => $order->customer_name ?: ($order->user->name ?? 'Pelanggan'),
                'customer_role' => $order->user?->role,
                'cashier_name' => $cashierName,
                'payment_method' => $order->payment_method,
                'order_source' => $order->order_source,
                'subtotal_price' => $subtotalPrice,
                'worker_discount_amount' => $workerDiscountAmount,
                'voucher_discount_amount' => $voucherDiscountAmount,
                'total_price' => $order->total_price,
                'amount_paid' => $amountPaid,
                'change_amount' => $changeAmount,
                'item_count' => $itemCount,
            ]
        );

        return $receipt->fresh([
            'order.items.product',
            'order.user',
        ]);
    }

    private function buildReceiptNumber(int $orderId): string
    {
        return 'KSM-' . now()->format('Ymd') . '-' . str_pad((string) $orderId, 6, '0', STR_PAD_LEFT);
    }
}
