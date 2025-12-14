<?php

namespace Database\Seeders;

use App\Models\Report;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ReportsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $reports = [
            [
                'title' => 'House Fire in Taman Sejahtera',
                'type' => 'Fire',
                'location' => 'Taman Sejahtera, Lubok Antu',
                'description' => 'House fire reported at Taman Sejahtera. Smoke visible from nearby houses. Fire department has been notified. Residents evacuating.',
                'status' => 'unresolved',
                'priority' => 'high',
                'reporter_name' => 'John Doe',
                'reporter_ic' => '901234-12-3456',
                'reporter_contact' => '011-9876 5432',
                'date_reported' => now()->subDays(1)->setHour(9)->setMinute(30),
                'date_updated' => null,
                'admin_notes' => null,
            ],
            [
                'title' => 'Flood in Jalan Sungai Besar',
                'type' => 'Flood',
                'location' => 'Jalan Sungai Besar, Lubok Antu',
                'description' => 'Heavy flooding reported in residential area. Water level rising. Residents moving to higher ground. Emergency services on standby.',
                'status' => 'in-progress',
                'priority' => 'high',
                'reporter_name' => 'Ahmad Abdullah',
                'reporter_ic' => '850615-08-5678',
                'reporter_contact' => '012-3456 7890',
                'date_reported' => now()->subDays(2)->setHour(14)->setMinute(15),
                'date_updated' => now()->subHours(3),
                'admin_notes' => 'Emergency services deployed. Evacuation in progress.',
            ],
            [
                'title' => 'Medical Emergency in Kampung Meruan',
                'type' => 'Medical Emergency',
                'location' => 'Kampung Meruan, Lubok Antu',
                'description' => 'Severe allergic reaction reported. Ambulance dispatched. Patient stable.',
                'status' => 'resolved',
                'priority' => 'low',
                'reporter_name' => 'Ahmad Abdullah',
                'reporter_ic' => '850615-08-5678',
                'reporter_contact' => '012-3456 7890',
                'date_reported' => now()->subDays(3)->setHour(11)->setMinute(00),
                'date_updated' => now()->subDays(2)->setHour(15)->setMinute(30),
                'admin_notes' => 'Patient transported to hospital. Status: Stable.',
            ],
            [
                'title' => 'Car Accident on Jalan Raya',
                'type' => 'Accident',
                'location' => 'Jalan Raya, Lubok Antu',
                'description' => 'Two-vehicle collision reported. Traffic congestion. Police on scene.',
                'status' => 'unresolved',
                'priority' => 'medium',
                'reporter_name' => 'Ali Ahmad',
                'reporter_ic' => '920101-14-9876',
                'reporter_contact' => '013-5555 6666',
                'date_reported' => now()->subHours(2)->setHour(16)->setMinute(45),
                'date_updated' => null,
                'admin_notes' => null,
            ],
            [
                'title' => 'Medical Emergency in Kampung Baru',
                'type' => 'Medical Emergency',
                'location' => 'Kampung Baru, Lubok Antu',
                'description' => 'Sudden chest pain reported. Ambulance en route. Paramedics assessing patient.',
                'status' => 'unresolved',
                'priority' => 'high',
                'reporter_name' => 'Sarah Lee',
                'reporter_ic' => '880520-03-2468',
                'reporter_contact' => '014-7777 8888',
                'date_reported' => now()->subHours(1)->setHour(17)->setMinute(20),
                'date_updated' => null,
                'admin_notes' => null,
            ],
            [
                'title' => 'Landslide on Bukit Tinggi Road',
                'type' => 'Landslide',
                'location' => 'Bukit Tinggi Road, Lubok Antu',
                'description' => 'Road blocked by landslide. Heavy rain causing instability. Structural engineers on standby.',
                'status' => 'in-progress',
                'priority' => 'medium',
                'reporter_name' => 'Jane Smith',
                'reporter_ic' => '900730-06-5432',
                'reporter_contact' => '015-9999 0000',
                'date_reported' => now()->subDays(1)->setHour(8)->setMinute(00),
                'date_updated' => now()->subHours(5),
                'admin_notes' => 'Road cordoned off. Engineering team assessing stability.',
            ],
            [
                'title' => 'Fire in Taman Indah',
                'type' => 'Fire',
                'location' => 'Taman Indah, Lubok Antu',
                'description' => 'Small house fire extinguished. Property damage assessed. No injuries reported.',
                'status' => 'resolved',
                'priority' => 'medium',
                'reporter_name' => 'John Doe',
                'reporter_ic' => '901234-12-3456',
                'reporter_contact' => '011-9876 5432',
                'date_reported' => now()->subDays(4)->setHour(10)->setMinute(30),
                'date_updated' => now()->subDays(3)->setHour(18)->setMinute(00),
                'admin_notes' => 'Fire contained. No injuries. Investigation completed.',
            ],
            [
                'title' => 'Car Accident on Jalan Raya Utama',
                'type' => 'Accident',
                'location' => 'Jalan Raya Utama, Lubok Antu',
                'description' => 'Single vehicle accident. Minor injuries. Towed away.',
                'status' => 'resolved',
                'priority' => 'low',
                'reporter_name' => 'Sarah Lee',
                'reporter_ic' => '880520-03-2468',
                'reporter_contact' => '014-7777 8888',
                'date_reported' => now()->subDays(5)->setHour(14)->setMinute(15),
                'date_updated' => now()->subDays(4)->setHour(16)->setMinute(45),
                'admin_notes' => 'Incident cleared. All parties accounted for.',
            ],
        ];

        foreach ($reports as $report) {
            Report::create($report);
        }
    }
}
