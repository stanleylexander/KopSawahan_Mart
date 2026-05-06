<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use Carbon\Carbon;

class ReportController extends Controller
{
    public function summary()
    {
        $year = now()->year;
        $startOfYear = Carbon::create($year, 1, 1)->startOfDay();
        $endOfYear = Carbon::create($year, 12, 31)->endOfDay();
        $startOfMonth = now()->startOfMonth();
        $endOfMonth = now()->endOfMonth();

        $monthlyItemsRaw = OrderItem::query()
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->selectRaw('MONTH(orders.created_at) as month_number, SUM(order_items.quantity) as total_quantity')
            ->where('orders.status', 'selesai')
            ->whereBetween('orders.created_at', [$startOfYear, $endOfYear])
            ->groupByRaw('MONTH(orders.created_at)')
            ->pluck('total_quantity', 'month_number');

        $monthlySales = collect(range(1, 12))->map(function ($monthNumber) use ($monthlyItemsRaw) {
            return [
                'month_number' => $monthNumber,
                'month_name' => Carbon::create()->month($monthNumber)->translatedFormat('M'),
                'total_quantity' => (int) ($monthlyItemsRaw[$monthNumber] ?? 0),
            ];
        })->values();

        $workerTotals = Order::query()
            ->join('users', 'orders.user_id', '=', 'users.id')
            ->select('users.id as worker_id', 'users.name as worker_name')
            ->selectRaw('SUM(orders.total_price) as total_nominal')
            ->selectRaw('COUNT(orders.id) as total_transactions')
            ->where('orders.status', 'selesai')
            ->where('users.role', User::ROLE_WORKER)
            ->whereBetween('orders.created_at', [$startOfYear, $endOfYear])
            ->groupBy('users.id', 'users.name')
            ->orderByDesc('total_nominal')
            ->get()
            ->map(function ($item) {
                return [
                    'worker_id' => (int) $item->worker_id,
                    'worker_name' => $item->worker_name,
                    'total_nominal' => (int) $item->total_nominal,
                    'total_transactions' => (int) $item->total_transactions,
                ];
            })
            ->values();

        $topProducts = OrderItem::query()
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->select('order_items.product_name')
            ->selectRaw('SUM(order_items.quantity) as total_quantity')
            ->selectRaw('SUM(order_items.quantity * order_items.price) as total_nominal')
            ->where('orders.status', 'selesai')
            ->whereBetween('orders.created_at', [$startOfYear, $endOfYear])
            ->groupBy('order_items.product_name')
            ->orderByDesc('total_quantity')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'product_name' => $item->product_name,
                    'total_quantity' => (int) $item->total_quantity,
                    'total_nominal' => (int) $item->total_nominal,
                ];
            })
            ->values();

        $paymentMethodBreakdown = Order::query()
            ->select('payment_method')
            ->selectRaw('COUNT(id) as total_orders')
            ->selectRaw('SUM(total_price) as total_nominal')
            ->where('status', 'selesai')
            ->whereBetween('created_at', [$startOfYear, $endOfYear])
            ->groupBy('payment_method')
            ->get()
            ->map(function ($item) {
                return [
                    'payment_method' => $item->payment_method,
                    'total_orders' => (int) $item->total_orders,
                    'total_nominal' => (int) $item->total_nominal,
                ];
            })
            ->values();

        $overview = [
            'year' => $year,
            'total_items_this_month' => (int) OrderItem::query()
                ->join('orders', 'order_items.order_id', '=', 'orders.id')
                ->where('orders.status', 'selesai')
                ->whereBetween('orders.created_at', [$startOfMonth, $endOfMonth])
                ->sum('order_items.quantity'),
            'total_revenue_this_month' => (int) Order::query()
                ->where('status', 'selesai')
                ->whereBetween('created_at', [$startOfMonth, $endOfMonth])
                ->sum('total_price'),
            'total_orders_this_month' => (int) Order::query()
                ->where('status', 'selesai')
                ->whereBetween('created_at', [$startOfMonth, $endOfMonth])
                ->count(),
        ];

        return response()->json([
            'overview' => $overview,
            'monthly_sales' => $monthlySales,
            'worker_totals' => $workerTotals,
            'top_products' => $topProducts,
            'payment_method_breakdown' => $paymentMethodBreakdown,
            'recommendations' => [
                'Produk terlaris per tahun untuk membantu stok dan restock.',
                'Komposisi metode pembayaran untuk melihat kebiasaan transaksi cash dan online.',
            ],
        ]);
    }
}
