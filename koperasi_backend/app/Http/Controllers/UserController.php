<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Order;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{

    // GET ALL USERS
    public function index()
    {
        return response()->json(User::all());
    }


    // PROFILE
    public function profile(Request $request)
    {
        $user = $request->user();
        $annualSpend = Order::where('user_id', $user->id)
            ->where('status', 'selesai')
            ->whereYear('created_at', now()->year)
            ->sum('total_price');

        return response()->json([
            "id" => $user->id,
            "name" => $user->name,
            "email" => $user->email,
            "phone_number" => $user->phone_number,
            "date_of_birth" => $user->date_of_birth,
            "gender" => $user->gender,
            "image" => $user->image,
            "role" => $user->role,
            "points" => $user->points,
            "annual_spend" => $annualSpend,
            "membership_level" => $this->getMembershipLevel($annualSpend),
        ]);
    }

    private function getMembershipLevel(int $annualSpend): string
    {
        if ($annualSpend >= 5000000) {
            return 'Platinum';
        }

        if ($annualSpend >= 3000000) {
            return 'Gold';
        }

        if ($annualSpend >= 1000000) {
            return 'Silver';
        }

        return 'Bronze';
    }

    // UPDATE PROFILE
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone_number' => 'nullable|string|max:20',
            'date_of_birth' => 'nullable|date',
            'gender' => 'nullable|in:male,female',
            'image' => 'nullable|image|mimes:jpg,jpeg,png',
        ]);

        if ($request->hasFile('image')) {
            if ($user->image) {
                Storage::disk('public')->delete($user->image);
            }

            $user->image = $request->file('image')->store('profiles', 'public');
        }

        $user->name = $request->name;
        $user->email = $request->email;
        $user->phone_number = $request->phone_number;
        $user->date_of_birth = $request->date_of_birth;
        $user->gender = $request->gender;

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    public function saveDeviceToken(Request $request)
    {
        $request->validate([
            'device_token' => 'nullable|string',
        ]);

        $user = $request->user();
        $user->device_token = $request->device_token;
        $user->save();

        return response()->json([
            'message' => 'Device token berhasil disimpan',
        ]);
    }


    // UPDATE ROLE
    public function updateRole(Request $request, $id)
    {
        $request->validate([
            'role' => 'required|in:member,worker,cashier,admin'
        ]);

        $user = User::findOrFail($id);
        $user->role = $request->role;
        $user->save();

        return response()->json([
            'message' => 'Role updated successfully',
            'user' => $user
        ]);
    }
}
