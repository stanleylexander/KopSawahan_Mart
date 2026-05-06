<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('registration_otps', function (Blueprint $table) {
            $table->string('otp_code')->change();
        });
    }

    public function down(): void
    {
        Schema::table('registration_otps', function (Blueprint $table) {
            $table->string('otp_code', 6)->change();
        });
    }
};
