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
        // Add Firebase columns to users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'firebase_uid')) {
                $table->string('firebase_uid')->nullable()->unique()->index();
            }
            if (!Schema::hasColumn('users', 'is_firebase_synced')) {
                $table->boolean('is_firebase_synced')->default(false);
            }
            if (!Schema::hasColumn('users', 'firebase_synced_at')) {
                $table->timestamp('firebase_synced_at')->nullable();
            }
        });

        // Create emergency_alerts table if it doesn't exist
        if (!Schema::hasTable('emergency_alerts')) {
            Schema::create('emergency_alerts', function (Blueprint $table) {
                $table->id();
                $table->string('firebase_id')->nullable()->unique()->index();
                $table->string('title');
                $table->text('description');
                $table->string('location');
                $table->enum('severity', ['low', 'medium', 'high'])->default('medium');
                $table->enum('status', ['active', 'resolved', 'cancelled'])->default('active');
                $table->boolean('synced_from_firebase')->default(false);
                $table->timestamp('created_at')->useCurrent();
                $table->timestamp('updated_at')->useCurrent();
            });
        }

        // Create notifications table if it doesn't exist
        if (!Schema::hasTable('notifications')) {
            Schema::create('notifications', function (Blueprint $table) {
                $table->id();
                $table->string('firebase_id')->nullable()->unique()->index();
                $table->unsignedBigInteger('user_id');
                $table->string('title');
                $table->text('message');
                $table->enum('type', ['emergency', 'aid_update', 'general'])->default('general');
                $table->boolean('is_read')->default(false);
                $table->boolean('synced_from_firebase')->default(false);
                $table->timestamp('created_at')->useCurrent();
                $table->timestamp('updated_at')->useCurrent();

                $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
                $table->index(['user_id', 'is_read']);
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndexIfExists(['firebase_uid']);
            $table->dropColumnIfExists(['firebase_uid', 'is_firebase_synced', 'firebase_synced_at']);
        });

        Schema::dropIfExists('emergency_alerts');
        Schema::dropIfExists('notifications');
    }
};
