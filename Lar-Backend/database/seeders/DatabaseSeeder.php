<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create admin user
        User::factory()->create([
            'full_name' => 'Admin User',
            'ic_no' => '960115-12-1234',
            'email' => 'admin@rescuenet.com',
            'phone_no' => '0123456789',
            'address' => 'Admin Office, Lubok Antu',
            'password' => Hash::make('password123'),
            'role' => 'admin',
            'is_active' => true,
        ]);

        // Create citizen user
        User::factory()->create([
            'full_name' => 'John Citizen',
            'ic_no' => '980225-08-5678',
            'email' => 'citizen@rescuenet.com',
            'phone_no' => '0129876543',
            'address' => 'Block A, Jalan Sejahtera, Lubok Antu',
            'password' => Hash::make('password123'),
            'role' => 'resident',
            'is_active' => true,
        ]);
    }
}
