<?php

require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$programs = App\Models\BantuanProgram::all();

echo "\n=== SEEDED AID PROGRAMS ===\n\n";
foreach($programs as $p) {
    echo sprintf(
        "[%d] %s\n    Status: %s | Amount: RM%s | Category: %s\n\n",
        $p->id,
        $p->title,
        $p->status,
        $p->aid_amount,
        $p->category
    );
}

echo "Total Programs: " . count($programs) . "\n";
echo "Active: " . $programs->where('status', 'Active')->count() . "\n";
echo "Inactive: " . $programs->where('status', 'Inactive')->count() . "\n";
