<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Models\Voucher;
use App\Models\UserVoucher;

class VoucherController extends Controller
{
    private function expireUserVouchers(int $userId): void
    {
        UserVoucher::where('user_id', $userId)
            ->where('status', 'unused')
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->update(['status' => 'used']);
    }

    // GET ALL VOUCHERS
    public function index()
    {
        return response()->json(Voucher::latest()->get());
    }

    // CREATE
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string',
            'description' => 'nullable|string',
            'required_points' => 'required|integer|min:0',
            'discount_amount' => 'required|integer|min:0|max:100',
            'max_discount_amount' => 'required|integer|min:0',
            'minimum_purchase_amount' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpg,jpeg,png',
            'expired_at' => 'nullable|date',
        ]);

        $imagePath = null;

        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('vouchers', 'public');
        }

        $voucher = Voucher::create([
            'name' => $request->name,
            'description' => $request->description,
            'required_points' => $request->required_points,
            'discount_amount' => $request->discount_amount,
            'max_discount_amount' => $request->max_discount_amount,
            'minimum_purchase_amount' => $request->minimum_purchase_amount,
            'image' => $imagePath,
            'expired_at' => $request->expired_at,
        ]);

        return response()->json([
            "message" => "Voucher berhasil dibuat",
            "data" => $voucher
        ], 201);
    }

    // UPDATE
    public function update($id, Request $request)
    {
        $voucher = Voucher::findOrFail($id);

        $request->validate([
            'name' => 'required|string',
            'description' => 'nullable|string',
            'required_points' => 'required|integer|min:0',
            'discount_amount' => 'required|integer|min:0|max:100',
            'max_discount_amount' => 'required|integer|min:0',
            'minimum_purchase_amount' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpg,jpeg,png',
            'expired_at' => 'nullable|date',
        ]);

        if ($request->hasFile('image')) {
            if ($voucher->image) {
                Storage::disk('public')->delete($voucher->image);
            }

            $voucher->image = $request->file('image')->store('vouchers', 'public');
        }

        $voucher->update([
            'name' => $request->name,
            'description' => $request->description,
            'required_points' => $request->required_points,
            'discount_amount' => $request->discount_amount,
            'max_discount_amount' => $request->max_discount_amount,
            'minimum_purchase_amount' => $request->minimum_purchase_amount,
            'image' => $voucher->image,
            'expired_at' => $request->expired_at,
        ]);

        return response()->json([
            "message" => "Voucher berhasil diupdate",
            "data" => $voucher
        ]);
    }

    // DELETE
    public function destroy($id)
    {
        $voucher = Voucher::findOrFail($id);

        if ($voucher->image) {
            Storage::disk('public')->delete($voucher->image);
        }

        $voucher->delete();

        return response()->json([
            "message" => "Voucher berhasil dihapus"
        ]);
    }

    // REDEEM
    public function redeem($id, Request $request)
    {
        $user = $request->user();
        $voucher = Voucher::findOrFail($id);

        if ($voucher->expired_at && $voucher->expired_at->isPast()) {
            return response()->json([
                "message" => "Voucher sudah expired"
            ], 422);
        }

        if ($user->points < $voucher->required_points) {
            return response()->json([
                "message" => "Poin tidak cukup"
            ], 400);
        }

        DB::beginTransaction();

        try {
            // KURANGI POINT
            $user->points -= $voucher->required_points;
            $user->save();

            // SIMPAN KE user_vouchers
            UserVoucher::create([
                'user_id' => $user->id,
                'voucher_id' => $voucher->id,
                'status' => 'unused',
                'expires_at' => $voucher->expired_at,
            ]);

            DB::commit();

            return response()->json([
                "message" => "Voucher berhasil ditukar"
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                "message" => "Terjadi kesalahan",
                "error" => $e->getMessage()
            ], 500);
        }
    }

    // GET USER VOUCHERS
    public function myVouchers(Request $request)
    {
        $user = $request->user();
        $this->expireUserVouchers($user->id);

        return response()->json(
            UserVoucher::with('voucher')
                ->where('user_id', $user->id)
                ->latest()
                ->get()
        );
    }
}
