<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE orders MODIFY user_id BIGINT UNSIGNED NULL');

        Schema::table('orders', function (Blueprint $table) {
            $table->enum('order_source', ['app', 'offline'])->default('app')->after('user_voucher_id');
            $table->string('customer_name')->nullable()->after('order_source');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['order_source', 'customer_name']);
        });

        DB::statement('ALTER TABLE orders MODIFY user_id BIGINT UNSIGNED NOT NULL');
    }
};
