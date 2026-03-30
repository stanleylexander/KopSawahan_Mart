<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'name',
        'required_points'
    ];

    public function users()
    {
        return $this->hasMany(UserVoucher::class);
    }
}
