<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'name',
        'description',
        'required_points',
        'discount_amount',
        'max_discount_amount',
        'minimum_purchase_amount',
        'image',
        'expired_at',
    ];

    protected $casts = [
        'expired_at' => 'datetime',
    ];

    public function users()
    {
        return $this->hasMany(UserVoucher::class);
    }
}
