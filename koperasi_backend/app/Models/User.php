<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    const ROLE_MEMBER = 'member';
    const ROLE_WORKER = 'worker';
    const ROLE_CASHIER = 'cashier';
    const ROLE_ADMIN = 'admin';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone_number',
        'date_of_birth',
        'gender',
        'role',
        'points'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function isAdmin()
    {
        return $this->role === self::ROLE_ADMIN;
    }

    public function isCashier()
    {
        return $this->role === self::ROLE_CASHIER;
    }

    public function isWorker()
    {
        return $this->role === self::ROLE_WORKER;
    }

    public function isMember()
    {
        return $this->role === self::ROLE_MEMBER;
    }

    public function vouchers()
    {
        return $this->hasMany(UserVoucher::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
