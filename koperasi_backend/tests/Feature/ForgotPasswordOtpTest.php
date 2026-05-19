<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ForgotPasswordOtpTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('password_reset_tokens');
        Schema::dropIfExists('users');

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('phone_number', 12);
            $table->date('date_of_birth');
            $table->enum('gender', ['Male', 'Female'])->nullable();
            $table->enum('role', ['member', 'worker', 'cashier', 'admin'])->default('member');
            $table->integer('points')->default(0);
            $table->timestamps();
        });

        Schema::create('password_reset_tokens', function (Blueprint $table) {
            $table->string('email')->primary();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->text('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function test_user_can_request_forgot_password_otp(): void
    {
        $this->createUser('budi@example.com');

        $response = $this->postJson('/api/forgot-password/request-otp', [
            'email' => 'budi@example.com',
        ]);

        $response->assertOk()
            ->assertJson([
                'message' => 'Kode OTP reset password berhasil dikirim ke email',
            ]);

        $resetToken = DB::table('password_reset_tokens')
            ->where('email', 'budi@example.com')
            ->first();

        $this->assertNotNull($resetToken);
        $this->assertNotSame(6, strlen($resetToken->token));
    }

    public function test_user_can_reset_password_with_valid_otp(): void
    {
        $this->createUser('siti@example.com');

        DB::table('password_reset_tokens')->insert([
            'email' => 'siti@example.com',
            'token' => Hash::make('123456'),
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/forgot-password/reset', [
            'email' => 'siti@example.com',
            'otp_code' => '123456',
            'password' => 'newpassword',
            'password_confirmation' => 'newpassword',
        ]);

        $response->assertOk()
            ->assertJson([
                'message' => 'Password berhasil diubah. Silakan login kembali.',
            ]);

        $user = User::where('email', 'siti@example.com')->first();

        $this->assertTrue(Hash::check('newpassword', $user->password));
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'siti@example.com',
        ]);
    }

    public function test_user_cannot_reset_password_with_wrong_otp(): void
    {
        $this->createUser('ani@example.com');

        DB::table('password_reset_tokens')->insert([
            'email' => 'ani@example.com',
            'token' => Hash::make('123456'),
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/forgot-password/reset', [
            'email' => 'ani@example.com',
            'otp_code' => '654321',
            'password' => 'newpassword',
            'password_confirmation' => 'newpassword',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'message' => 'Kode OTP salah',
            ]);

        $user = User::where('email', 'ani@example.com')->first();

        $this->assertTrue(Hash::check('password', $user->password));
    }

    private function createUser(string $email): User
    {
        return User::create([
            'name' => 'User',
            'email' => $email,
            'password' => Hash::make('password'),
            'phone_number' => '081234567890',
            'date_of_birth' => '2000-01-01',
            'gender' => 'Male',
            'role' => User::ROLE_MEMBER,
            'points' => 0,
        ]);
    }
}
