<?php

namespace Tests\Feature;

use App\Models\RegistrationOtp;
use App\Models\User;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class RegisterOtpTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('registration_otps');
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

        Schema::create('registration_otps', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('phone_number', 12);
            $table->date('date_of_birth');
            $table->enum('gender', ['Male', 'Female']);
            $table->string('otp_code');
            $table->timestamp('expires_at');
            $table->timestamps();
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

    public function test_user_can_request_register_otp(): void
    {
        $response = $this->postJson('/api/register/request-otp', [
            'name' => 'Budi',
            'email' => 'budi@example.com',
            'password' => 'password',
            'phone_number' => '081234567890',
            'date_of_birth' => '2000-01-01',
            'gender' => 'Male',
        ]);

        $response->assertOk()
            ->assertJson([
                'message' => 'Kode OTP berhasil dikirim ke email',
            ]);

        $pendingRegistration = RegistrationOtp::where('email', 'budi@example.com')->first();

        $this->assertNotNull($pendingRegistration);
        $this->assertNotSame(6, strlen($pendingRegistration->otp_code));
        $this->assertTrue(Hash::check('password', $pendingRegistration->password));
    }

    public function test_user_can_verify_register_otp(): void
    {
        RegistrationOtp::create([
            'name' => 'Siti',
            'email' => 'siti@example.com',
            'password' => Hash::make('password'),
            'phone_number' => '081234567891',
            'date_of_birth' => '2001-02-03',
            'gender' => 'Female',
            'otp_code' => Hash::make('123456'),
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/register/verify-otp', [
            'email' => 'siti@example.com',
            'otp_code' => '123456',
        ]);

        $response->assertOk()
            ->assertJson([
                'message' => 'Register berhasil',
            ])
            ->assertJsonStructure([
                'token',
                'user' => ['id', 'name', 'email', 'role'],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'siti@example.com',
            'role' => User::ROLE_MEMBER,
        ]);
        $this->assertDatabaseMissing('registration_otps', [
            'email' => 'siti@example.com',
        ]);
    }

    public function test_user_cannot_verify_with_wrong_otp(): void
    {
        RegistrationOtp::create([
            'name' => 'Ani',
            'email' => 'ani@example.com',
            'password' => Hash::make('password'),
            'phone_number' => '081234567892',
            'date_of_birth' => '2002-03-04',
            'gender' => 'Female',
            'otp_code' => Hash::make('123456'),
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/register/verify-otp', [
            'email' => 'ani@example.com',
            'otp_code' => '654321',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'message' => 'Kode OTP salah',
            ]);

        $this->assertDatabaseMissing('users', [
            'email' => 'ani@example.com',
        ]);
    }
}
