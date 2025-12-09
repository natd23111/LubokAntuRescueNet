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
        Schema::create('aid_requests', function (Blueprint $table) {
        $table->id(); // report_id
        $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
        $table->enum('aid_type', ['Food', 'Financial', 'Medical', 'Other']);
        $table->integer('household_size');
        $table->string('income_level')->nullable();
        $table->text('supporting_notes')->nullable();
        $table->enum('status', ['Submitted', 'In Process', 'Completed', 'Rejected'])->default('Submitted');
        $table->text('admin_remarks')->nullable();
        $table->unsignedBigInteger('admin_id')->nullable(); // optional, admin who updates
        $table->enum('report_type', ['emergency', 'aid'])->default('aid'); // optional
        $table->timestamp('submitted_at')->useCurrent();
        $table->timestamps();
    });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('aid_requests');
    }
};
