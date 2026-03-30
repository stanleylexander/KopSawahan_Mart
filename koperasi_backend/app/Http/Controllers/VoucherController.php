<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Voucher;
use App\Models\UserVoucher;

class VoucherController extends Controller
{
    // GET ALL VOUCHERS
    public function index()
    {
        return response()->json(Voucher::all());
    }

    // CREATE (ADMIN)
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'required_points' => 'required|integer'
        ]);

        $voucher = Voucher::create($request->all());

        return response()->json($voucher);
    }

    // REDEEM
    public function redeem($id, Request $request)
    {
        $user = $request->user();
        $voucher = Voucher::findOrFail($id);

        // ❌ poin tidak cukup
        if ($user->points < $voucher->required_points) {
            return response()->json([
                "message" => "Poin tidak cukup"
            ], 400);
        }

        // ✅ kurangi poin
        $user->points -= $voucher->required_points;
        $user->save();

        // ✅ simpan ke user_vouchers
        UserVoucher::create([
            'user_id' => $user->id,
            'voucher_id' => $voucher->id,
        ]);

        return response()->json([
            "message" => "Voucher berhasil ditukar"
        ]);
    }

    // GET USER VOUCHERS
    public function myVouchers(Request $request)
    {
        $user = $request->user();

        return response()->json(
            UserVoucher::with('voucher')
                ->where('user_id', $user->id)
                ->get()
        );
    }
}
