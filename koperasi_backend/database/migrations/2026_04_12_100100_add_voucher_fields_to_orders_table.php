<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('user_voucher_id')->nullable()->after('user_id')->constrained('user_vouchers')->nullOnDelete();
            $table->integer('discount_amount')->default(0)->after('total_price');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_voucher_id');
            $table->dropColumn('discount_amount');
        });
    }
};
