<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UserVoucher extends Model
{
    protected $fillable = [
        'user_id',
        'voucher_id',
        'status'
    ];

    public function voucher()
    {
        return $this->belongsTo(Voucher::class);
    }
}
