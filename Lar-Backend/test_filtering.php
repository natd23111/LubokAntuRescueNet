<?php

require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\BantuanProgram;

echo "\n";
echo "═══════════════════════════════════════════════════════════════\n";
echo "  Enhanced Filtering & Search Demonstration\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

// Test 1: All programs
echo "1️⃣  ALL PROGRAMS (Total Count)\n";
echo "───────────────────────────────────────────────────────────────\n";
$total = BantuanProgram::count();
echo "Total programs in database: $total\n\n";

// Test 2: Filter by status
echo "2️⃣  FILTER BY STATUS\n";
echo "───────────────────────────────────────────────────────────────\n";
$active = BantuanProgram::where('status', 'Active')->count();
$inactive = BantuanProgram::where('status', 'Inactive')->count();
echo "Active programs: $active\n";
echo "Inactive programs: $inactive\n\n";

// Test 3: Filter by category
echo "3️⃣  FILTER BY CATEGORY\n";
echo "───────────────────────────────────────────────────────────────\n";
$categories = BantuanProgram::whereNotNull('category')
    ->distinct()
    ->pluck('category')
    ->sort()
    ->values();
echo "Available categories: " . implode(', ', $categories->toArray()) . "\n\n";
echo "Programs by category:\n";
foreach ($categories as $cat) {
    $count = BantuanProgram::where('category', $cat)->count();
    echo "  • $cat: $count program(s)\n";
}
echo "\n";

// Test 4: Filter by program type
echo "4️⃣  FILTER BY PROGRAM TYPE\n";
echo "───────────────────────────────────────────────────────────────\n";
$types = BantuanProgram::whereNotNull('program_type')
    ->distinct()
    ->pluck('program_type')
    ->sort()
    ->values();
echo "Available types: " . implode(', ', $types->toArray()) . "\n\n";
echo "Programs by type:\n";
foreach ($types as $type) {
    $count = BantuanProgram::where('program_type', $type)->count();
    echo "  • $type: $count program(s)\n";
}
echo "\n";

// Test 5: Filter by amount range
echo "5️⃣  FILTER BY AMOUNT RANGE\n";
echo "───────────────────────────────────────────────────────────────\n";
$minAmount = BantuanProgram::whereNotNull('aid_amount')->min('aid_amount');
$maxAmount = BantuanProgram::whereNotNull('aid_amount')->max('aid_amount');
$avgAmount = BantuanProgram::whereNotNull('aid_amount')->avg('aid_amount');
echo "Minimum aid amount: RM" . number_format($minAmount, 2) . "\n";
echo "Maximum aid amount: RM" . number_format($maxAmount, 2) . "\n";
echo "Average aid amount: RM" . number_format($avgAmount, 2) . "\n";
echo "Total aid value: RM" . number_format(BantuanProgram::sum('aid_amount'), 2) . "\n\n";

// Test 6: Search
echo "6️⃣  SEARCH FUNCTIONALITY\n";
echo "───────────────────────────────────────────────────────────────\n";
$searchTerm = 'financial';
$searchResults = BantuanProgram::where(function ($q) use ($searchTerm) {
    $q->where('title', 'like', "%{$searchTerm}%")
      ->orWhere('description', 'like', "%{$searchTerm}%")
      ->orWhere('criteria', 'like', "%{$searchTerm}%");
})->count();
echo "Search for '$searchTerm': Found $searchResults program(s)\n\n";

// Test 7: Combined filters
echo "7️⃣  COMBINED FILTERS\n";
echo "───────────────────────────────────────────────────────────────\n";
$combined = BantuanProgram::where('status', 'Active')
    ->where('category', 'Financial')
    ->where('aid_amount', '>=', 300)
    ->count();
echo "Active + Financial + Amount ≥ RM300: $combined program(s)\n\n";

// Test 8: Sorting
echo "8️⃣  SORTING EXAMPLES\n";
echo "───────────────────────────────────────────────────────────────\n";
echo "Programs sorted by aid amount (descending):\n";
$sorted = BantuanProgram::orderBy('aid_amount', 'desc')->get();
foreach ($sorted as $p) {
    echo sprintf("  • %s - RM%s\n", $p->title, $p->aid_amount);
}
echo "\n";

// Test 9: Statistics
echo "9️⃣  STATISTICS\n";
echo "───────────────────────────────────────────────────────────────\n";
$stats = [
    'total' => BantuanProgram::count(),
    'active' => BantuanProgram::where('status', 'Active')->count(),
    'inactive' => BantuanProgram::where('status', 'Inactive')->count(),
    'by_category' => BantuanProgram::select('category')
        ->selectRaw('count(*) as count')
        ->whereNotNull('category')
        ->groupBy('category')
        ->get(),
    'by_type' => BantuanProgram::select('program_type')
        ->selectRaw('count(*) as count')
        ->whereNotNull('program_type')
        ->groupBy('program_type')
        ->get(),
];

echo "Total: " . $stats['total'] . " programs\n";
echo "Active: " . $stats['active'] . " programs\n";
echo "Inactive: " . $stats['inactive'] . " programs\n";
echo "By Category:\n";
foreach ($stats['by_category'] as $cat) {
    echo "  • {$cat->category}: {$cat->count}\n";
}
echo "By Type:\n";
foreach ($stats['by_type'] as $type) {
    echo "  • {$type->program_type}: {$type->count}\n";
}
echo "\n";

// Test 10: Active programs only (for residents)
echo "🔟 ACTIVE PROGRAMS (For Residents)\n";
echo "───────────────────────────────────────────────────────────────\n";
$activePrograms = BantuanProgram::where('status', 'Active')->orderBy('created_at', 'desc')->get();
foreach ($activePrograms as $p) {
    echo sprintf("  • %s (%s) - RM%s\n", $p->title, $p->category, $p->aid_amount);
}
echo "\n";

echo "═══════════════════════════════════════════════════════════════\n";
echo "✅ All filtering tests completed successfully!\n";
echo "═══════════════════════════════════════════════════════════════\n\n";
