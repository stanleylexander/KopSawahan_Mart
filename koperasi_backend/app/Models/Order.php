<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    protected $fillable = [
        'user_id',
        'user_voucher_id',
        'order_source',
        'customer_name',
        'payment_method',
        'status',
        'total_price',
        'discount_amount',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function userVoucher()
    {
        return $this->belongsTo(UserVoucher::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function receipt()
    {
        return $this->hasOne(Receipt::class);
    }
}
