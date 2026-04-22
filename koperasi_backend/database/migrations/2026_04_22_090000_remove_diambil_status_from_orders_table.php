<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("UPDATE orders SET status = 'selesai' WHERE status = 'diambil'");
        DB::statement("UPDATE orders SET status = 'pending' WHERE status = 'diproses'");
        DB::statement("ALTER TABLE orders MODIFY status ENUM('pending', 'selesai') DEFAULT 'pending'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE orders MODIFY status ENUM('pending', 'diproses', 'selesai', 'diambil') DEFAULT 'pending'");
    }
};
