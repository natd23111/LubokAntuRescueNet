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
    Schema::create('emergency_reports', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained('users')->onDelete('cascade');

        $table->enum('incident_type', [
            'Fire', 'Flood', 'Accident', 'Health', 'Other'
        ]);

        $table->text('description')->nullable();
        $table->string('incident_location');
        $table->decimal('latitude', 10, 7)->nullable();
        $table->decimal('longitude', 10, 7)->nullable();

        $table->string('incident_photo')->nullable();

        $table->enum('status', ['Submitted', 'In Process', 'Completed'])
              ->default('Submitted');

        $table->text('admin_remarks')->nullable();

        $table->timestamps();
    });
}
    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('emergency_reports');
    }
};
