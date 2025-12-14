<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\BantuanProgram;
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
        $admin = User::factory()->create([
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

        // Create aid programs
        BantuanProgram::create([
            'title' => 'B40 Financial Assistance 2025',
            'description' => 'Monthly financial assistance for households in the B40 category. Program provides RM200-500 monthly aid based on household income verification.',
            'category' => 'Financial',
            'program_type' => 'Monthly',
            'aid_amount' => 350,
            'criteria' => 'Household monthly income below RM2000, Malaysian citizen with valid IC',
            'start_date' => '2025-01-01',
            'end_date' => '2025-12-31',
            'status' => 'Active',
            'admin_id' => $admin->id,
            'admin_remarks' => 'Active program for 2025',
        ]);

        BantuanProgram::create([
            'title' => 'Disaster Relief Fund',
            'description' => 'Emergency assistance for residents affected by floods, landslides, and other natural disasters. Immediate cash aid and recovery support.',
            'category' => 'Emergency',
            'program_type' => 'One-time',
            'aid_amount' => 1500,
            'criteria' => 'Must be affected by natural disaster, provide proof of residence and damage',
            'start_date' => '2024-11-01',
            'end_date' => '2025-12-31',
            'status' => 'Active',
            'admin_id' => $admin->id,
            'admin_remarks' => 'Ongoing program for disaster-affected residents',
        ]);

        BantuanProgram::create([
            'title' => 'Medical Emergency Fund',
            'description' => 'Assistance for medical emergencies and critical healthcare expenses. Covers hospitalization, emergency treatments, and essential medications.',
            'category' => 'Medical',
            'program_type' => 'One-time',
            'aid_amount' => 2000,
            'criteria' => 'Diagnosed medical emergency, income below RM4000/month, valid medical documents',
            'start_date' => '2025-01-01',
            'end_date' => '2025-12-31',
            'status' => 'Active',
            'admin_id' => $admin->id,
            'admin_remarks' => 'Medical assistance program',
        ]);

        BantuanProgram::create([
            'title' => 'Education Scholarship Program',
            'description' => 'Scholarships for underprivileged students pursuing primary, secondary, or tertiary education. Covers tuition fees and educational materials.',
            'category' => 'Education',
            'program_type' => 'Quarterly',
            'aid_amount' => 500,
            'criteria' => 'Student with household income below RM3000/month, academic records required',
            'start_date' => '2025-01-15',
            'end_date' => '2025-12-31',
            'status' => 'Active',
            'admin_id' => $admin->id,
            'admin_remarks' => 'Scholarship for deserving students',
        ]);

        BantuanProgram::create([
            'title' => 'Housing Assistance Program',
            'description' => 'Support for housing renovation, repairs, and construction for low-income families. Includes materials and labor support.',
            'category' => 'Housing',
            'program_type' => 'One-time',
            'aid_amount' => 3000,
            'criteria' => 'Own residential land/house, household income below RM2500/month',
            'start_date' => '2025-02-01',
            'end_date' => '2025-12-31',
            'status' => 'Inactive',
            'admin_id' => $admin->id,
            'admin_remarks' => 'Program suspended for budget allocation',
        ]);

        // Seed reports
        $this->call(ReportsSeeder::class);
    }
}
