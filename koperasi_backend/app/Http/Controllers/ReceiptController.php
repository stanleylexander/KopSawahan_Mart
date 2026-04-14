<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Receipt;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    public function myReceipts(Request $request)
    {
        $receipts = Receipt::with(['order.items', 'order.user'])
            ->whereHas('order', function ($query) use ($request) {
                $query->where('user_id', $request->user()->id);
            })
            ->latest()
            ->get();

        return response()->json($receipts);
    }

    public function show(Request $request, $id)
    {
        $receipt = Receipt::with(['order.items', 'order.user'])
            ->findOrFail($id);

        $order = $receipt->order;
        $user = $request->user();

        if ($user->isCashier()) {
            return response()->json($receipt);
        }

        if ($order->user_id !== $user->id) {
            abort(403, 'Kamu tidak bisa melihat nota ini');
        }

        return response()->json($receipt);
    }

    public function markAsPrinted($id)
    {
        $receipt = Receipt::findOrFail($id);

        $receipt->update([
            'print_status' => 'printed',
            'printed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Status print berhasil diupdate',
        ]);
    }
}
