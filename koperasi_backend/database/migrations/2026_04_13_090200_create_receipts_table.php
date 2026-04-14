<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->string('receipt_number')->unique();
            $table->enum('receipt_type', ['digital', 'print']);
            $table->enum('print_status', ['pending', 'printed', 'not_needed'])->default('pending');
            $table->string('customer_name');
            $table->string('customer_role')->nullable();
            $table->string('cashier_name')->nullable();
            $table->string('payment_method');
            $table->string('order_source');
            $table->integer('subtotal_price')->default(0);
            $table->integer('worker_discount_amount')->default(0);
            $table->integer('voucher_discount_amount')->default(0);
            $table->integer('total_price')->default(0);
            $table->integer('item_count')->default(0);
            $table->timestamp('printed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};
