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
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->string('title')->nullable();
            $table->string('type'); // Fire, Flood, Medical Emergency, Accident, Landslide, etc.
            $table->string('location');
            $table->text('description');
            $table->enum('status', ['unresolved', 'in-progress', 'resolved'])->default('unresolved');
            $table->enum('priority', ['low', 'medium', 'high'])->default('medium');
            $table->string('reporter_name');
            $table->string('reporter_ic');
            $table->string('reporter_contact');
            $table->dateTime('date_reported');
            $table->dateTime('date_updated')->nullable();
            $table->text('admin_notes')->nullable();
            $table->string('image_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
