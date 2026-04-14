<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Receipt extends Model
{
    protected $fillable = [
        'order_id',
        'receipt_number',
        'receipt_type',
        'print_status',
        'customer_name',
        'customer_role',
        'cashier_name',
        'payment_method',
        'order_source',
        'subtotal_price',
        'worker_discount_amount',
        'voucher_discount_amount',
        'total_price',
        'item_count',
        'printed_at',
    ];

    protected $casts = [
        'printed_at' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
