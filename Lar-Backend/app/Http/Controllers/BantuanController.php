<?php

namespace App\Http\Controllers;

use App\Models\BantuanProgram;
use Illuminate\Http\Request;

class BantuanController extends Controller
{
    // Get all programs with filtering and pagination
    public function index(Request $request)
    {
        $query = BantuanProgram::query();

        // Filter by status
        if ($request->has('status') && $request->status) {
            $query->where('status', $request->status);
        }

        // Filter by category
        if ($request->has('category') && $request->category) {
            $query->where('category', $request->category);
        }

        // Search by title or description
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Sort by creation date (latest first)
        $programs = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $programs,
            'count' => $programs->count(),
        ]);
    }

    // Get single program by ID
    public function show($id)
    {
        $program = BantuanProgram::findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $program,
        ]);
    }

    // Create new program (Admin only)
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'category' => 'nullable|string',
            'program_type' => 'nullable|string',
            'aid_amount' => 'nullable|numeric',
            'criteria' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'status' => 'nullable|in:Active,Inactive',
        ]);

        $program = BantuanProgram::create(array_merge(
            $validated,
            [
                'admin_id' => auth()->id(),
                'status' => $validated['status'] ?? 'Active',
            ]
        ));

        return response()->json([
            'success' => true,
            'message' => 'Program created successfully',
            'data' => $program,
        ], 201);
    }

    // Update program (Admin only)
    public function update(Request $request, $id)
    {
        $program = BantuanProgram::findOrFail($id);

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'category' => 'nullable|string',
            'program_type' => 'nullable|string',
            'aid_amount' => 'nullable|numeric',
            'criteria' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'status' => 'nullable|in:Active,Inactive',
            'admin_remarks' => 'nullable|string',
        ]);

        $program->update(array_merge(
            $validated,
            ['admin_id' => auth()->id()]
        ));

        return response()->json([
            'success' => true,
            'message' => 'Program updated successfully',
            'data' => $program,
        ]);
    }

    // Toggle program status (Active/Inactive)
    public function toggleStatus($id)
    {
        $program = BantuanProgram::findOrFail($id);

        $newStatus = $program->status === 'Active' ? 'Inactive' : 'Active';
        $program->update([
            'status' => $newStatus,
            'admin_id' => auth()->id(),
            'admin_remarks' => "Status changed to {$newStatus} by " . auth()->user()->full_name,
        ]);

        return response()->json([
            'success' => true,
            'message' => "Program status changed to {$newStatus}",
            'data' => $program,
        ]);
    }

    // Delete program (Admin only)
    public function destroy($id)
    {
        $program = BantuanProgram::findOrFail($id);
        $program->delete();

        return response()->json([
            'success' => true,
            'message' => 'Program deleted successfully',
        ]);
    }

    // Get programs by category
    public function getByCategory($category)
    {
        $programs = BantuanProgram::where('category', $category)
                                  ->where('status', 'Active')
                                  ->orderBy('created_at', 'desc')
                                  ->get();

        return response()->json([
            'success' => true,
            'category' => $category,
            'data' => $programs,
            'count' => $programs->count(),
        ]);
    }

    // Get all available categories
    public function getCategories()
    {
        $categories = BantuanProgram::whereNotNull('category')
                                     ->distinct()
                                     ->pluck('category');

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    // Get programs statistics
    public function getStats()
    {
        $stats = [
            'total' => BantuanProgram::count(),
            'active' => BantuanProgram::where('status', 'Active')->count(),
            'inactive' => BantuanProgram::where('status', 'Inactive')->count(),
            'by_category' => BantuanProgram::select('category')
                                          ->selectRaw('count(*) as count')
                                          ->whereNotNull('category')
                                          ->groupBy('category')
                                          ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}

