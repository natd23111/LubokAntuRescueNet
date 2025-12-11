<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('bantuan_programs', function (Blueprint $table) {
            $table->string('category')->nullable()->after('description');
            $table->string('program_type')->nullable()->after('category');
            $table->decimal('aid_amount', 10, 2)->nullable()->after('program_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bantuan_programs', function (Blueprint $table) {
            $table->dropColumn(['category', 'program_type', 'aid_amount']);
        });
    }
};
