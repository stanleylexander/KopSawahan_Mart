<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use App\Models\RegistrationOtp;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;

class AuthController extends Controller
{
    public function requestRegisterOtp(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'phone_number' => 'required|string|max:12',
            'date_of_birth' => 'required|date',
            'gender' => 'required|in:Male,Female',
        ]);

        $email = strtolower($request->email);
        $otpCode = (string) random_int(100000, 999999);

        RegistrationOtp::updateOrCreate(
            ['email' => $email],
            [
                'name' => $request->name,
                'password' => Hash::make($request->password),
                'phone_number' => $request->phone_number,
                'date_of_birth' => $request->date_of_birth,
                'gender' => $request->gender,
                'otp_code' => Hash::make($otpCode),
                'expires_at' => now()->addMinutes(10),
            ]
        );

        Mail::raw(
            "Kode OTP register KopSawahan Mart kamu adalah: {$otpCode}. Kode ini berlaku selama 10 menit.",
            function ($message) use ($email) {
                $message->to($email)
                    ->subject('Kode OTP Register KopSawahan Mart');
            }
        );

        return response()->json([
            'message' => 'Kode OTP berhasil dikirim ke email',
        ]);
    }

    public function verifyRegisterOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp_code' => 'required|string|size:6',
        ]);

        $email = strtolower($request->email);
        $pendingRegistration = RegistrationOtp::where('email', $email)->first();

        if (!$pendingRegistration) {
            return response()->json([
                'message' => 'Data register tidak ditemukan. Silakan daftar ulang.',
            ], 404);
        }

        if ($pendingRegistration->expires_at->isPast()) {
            $pendingRegistration->delete();

            return response()->json([
                'message' => 'Kode OTP sudah kadaluarsa. Silakan minta kode baru.',
            ], 422);
        }

        if (!Hash::check($request->otp_code, $pendingRegistration->otp_code)) {
            return response()->json([
                'message' => 'Kode OTP salah',
            ], 422);
        }

        try {
            $user = DB::transaction(function () use ($pendingRegistration) {
                if (User::where('email', $pendingRegistration->email)->exists()) {
                    $pendingRegistration->delete();
                    return null;
                }

                $user = User::create([
                    'name' => $pendingRegistration->name,
                    'email' => $pendingRegistration->email,
                    'password' => $pendingRegistration->password,
                    'phone_number' => $pendingRegistration->phone_number,
                    'date_of_birth' => $pendingRegistration->date_of_birth,
                    'gender' => $pendingRegistration->gender,
                    'role' => User::ROLE_MEMBER,
                    'points' => 0
                ]);

                $pendingRegistration->delete();

                return $user;
            });
        } catch (QueryException) {
            $pendingRegistration->delete();

            return response()->json([
                'message' => 'Email sudah terdaftar. Silakan login.',
            ], 422);
        }

        if (!$user) {
            return response()->json([
                'message' => 'Email sudah terdaftar. Silakan login.',
            ], 422);
        }

        $token = $user->createToken('koperasi_token')->plainTextToken;

        return response()->json([
            'message' => 'Register berhasil',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function requestForgotPasswordOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $email = strtolower($request->email);
        $otpCode = (string) random_int(100000, 999999);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $email],
            [
                'token' => Hash::make($otpCode),
                'created_at' => now(),
            ]
        );

        Mail::raw(
            "Kode OTP reset password KopSawahan Mart kamu adalah: {$otpCode}. Kode ini berlaku selama 10 menit.",
            function ($message) use ($email) {
                $message->to($email)
                    ->subject('Kode OTP Reset Password KopSawahan Mart');
            }
        );

        return response()->json([
            'message' => 'Kode OTP reset password berhasil dikirim ke email',
        ]);
    }

    public function resetPasswordWithOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email|exists:users,email',
            'otp_code' => 'required|string|size:6',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $email = strtolower($request->email);
        $resetToken = DB::table('password_reset_tokens')
            ->where('email', $email)
            ->first();

        if (!$resetToken) {
            return response()->json([
                'message' => 'Kode OTP tidak ditemukan. Silakan minta kode baru.',
            ], 404);
        }

        if (now()->subMinutes(10)->greaterThan($resetToken->created_at)) {
            DB::table('password_reset_tokens')->where('email', $email)->delete();

            return response()->json([
                'message' => 'Kode OTP sudah kadaluarsa. Silakan minta kode baru.',
            ], 422);
        }

        if (!Hash::check($request->otp_code, $resetToken->token)) {
            return response()->json([
                'message' => 'Kode OTP salah',
            ], 422);
        }

        $status = Password::broker()->reset(
            [
                'email' => $email,
                'password' => $request->password,
                'password_confirmation' => $request->password_confirmation,
                'token' => $request->otp_code,
            ],
            function (User $user, string $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                ])->save();

                $user->tokens()->delete();
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'message' => 'Gagal mengubah password. Silakan minta kode baru.',
            ], 422);
        }

        return response()->json([
            'message' => 'Password berhasil diubah. Silakan login kembali.',
        ]);
    }

    // REGISTER
    public function register(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone_number' => $request->phone_number,
            'date_of_birth' => $request->date_of_birth,
            'gender' => $request->gender,
            'points' => 0

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

        // HAPUS TOKEN LAMA
        $user->tokens()->delete();

        // BUAT TOKEN BARU
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
