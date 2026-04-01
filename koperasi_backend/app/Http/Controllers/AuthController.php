<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Point;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // REGISTER
    public function register(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone_number' => $request->phone_number,
            'date_of_birth' => $request->date_of_birth,
            'gender' => $request->gender

        ]);

        Point::create([
            'user_id' => $user->id,
            'point' => 0
        ]);

        //TOKEN DIBUAT DI SINI
        $token = $user->createToken('koperasi_token')->plainTextToken;

        return response()->json([
            'message' => 'Register sucessfully',
            'token' => $token,
            'user' => $user
        ]);
    }


    // LOGIN
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                "message" => "Email atau password salah"
            ], 401);
        }

        // Hapus token lama (optional)
        $user->tokens()->delete();

        // Buat token baru
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            "message" => "Login berhasil",
            "token" => $token,
            "user" => $user
        ]);
    }


    // LOGOUT
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            "message" => "Logout berhasil"
        ]);
    }
}
