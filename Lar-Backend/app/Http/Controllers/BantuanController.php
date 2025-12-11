<?php

namespace App\Http\Controllers;

use App\Models\BantuanProgram;
use Illuminate\Http\Request;

class BantuanController extends Controller
{
    // Get all programs with advanced filtering and pagination
    public function index(Request $request)
    {
        $query = BantuanProgram::query();

        // Filter by status
        if ($request->has('status') && $request->status) {
            $statusValue = $request->status === 'active' ? 'Active' :
                          ($request->status === 'inactive' ? 'Inactive' : $request->status);
            $query->where('status', $statusValue);
        }

        // Filter by category
        if ($request->has('category') && $request->category) {
            $query->where('category', $request->category);
        }

        // Filter by program type
        if ($request->has('program_type') && $request->program_type) {
            $query->where('program_type', $request->program_type);
        }

        // Filter by date range
        if ($request->has('start_date_from') && $request->start_date_from) {
            $query->whereDate('start_date', '>=', $request->start_date_from);
        }
        if ($request->has('start_date_to') && $request->start_date_to) {
            $query->whereDate('start_date', '<=', $request->start_date_to);
        }

        // Filter by aid amount range
        if ($request->has('min_amount') && $request->min_amount) {
            $query->where('aid_amount', '>=', $request->min_amount);
        }
        if ($request->has('max_amount') && $request->max_amount) {
            $query->where('aid_amount', '<=', $request->max_amount);
        }

        // Search by title, description, or criteria
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('criteria', 'like', "%{$search}%");
            });
        }

        // Sorting
        $sortBy = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        $validSortColumns = ['id', 'title', 'status', 'aid_amount', 'created_at', 'start_date'];
        $validOrders = ['asc', 'desc'];

        if (in_array($sortBy, $validSortColumns) && in_array($sortOrder, $validOrders)) {
            $query->orderBy($sortBy, $sortOrder);
        } else {
            $query->orderBy('created_at', 'desc');
        }

        // Pagination
        $perPage = min($request->input('per_page', 15), 100); // Max 100 per page
        $programs = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $programs->items(),
            'count' => $programs->total(),
            'current_page' => $programs->currentPage(),
            'total_pages' => $programs->lastPage(),
            'per_page' => $programs->perPage(),
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
                                     ->pluck('category')
                                     ->sort()
                                     ->values();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    // Get all available program types
    public function getProgramTypes()
    {
        $types = BantuanProgram::whereNotNull('program_type')
                               ->distinct()
                               ->pluck('program_type')
                               ->sort()
                               ->values();

        return response()->json([
            'success' => true,
            'data' => $types,
        ]);
    }

    // Get programs statistics with detailed breakdown
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
            'by_type' => BantuanProgram::select('program_type')
                                       ->selectRaw('count(*) as count')
                                       ->whereNotNull('program_type')
                                       ->groupBy('program_type')
                                       ->get(),
            'total_aid_amount' => BantuanProgram::sum('aid_amount'),
            'average_aid_amount' => BantuanProgram::whereNotNull('aid_amount')->avg('aid_amount'),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    // Get programs by criteria (flexible search)
    public function search(Request $request)
    {
        $query = BantuanProgram::query();

        // Multi-field search
        if ($request->has('q') && $request->q) {
            $searchTerm = $request->q;
            $query->where(function ($q) use ($searchTerm) {
                $q->where('title', 'like', "%{$searchTerm}%")
                  ->orWhere('description', 'like', "%{$searchTerm}%")
                  ->orWhere('criteria', 'like', "%{$searchTerm}%");
            });
        }

        $perPage = min($request->input('per_page', 15), 100);
        $results = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $results->items(),
            'count' => $results->total(),
            'current_page' => $results->currentPage(),
            'total_pages' => $results->lastPage(),
        ]);
    }

    // Get active programs only (for residents)
    public function getActive(Request $request)
    {
        $query = BantuanProgram::where('status', 'Active');

        // Filter by category
        if ($request->has('category') && $request->category) {
            $query->where('category', $request->category);
        }

        // Search
        if ($request->has('search') && $request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $perPage = min($request->input('per_page', 15), 100);
        $programs = $query->orderBy('created_at', 'desc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $programs->items(),
            'count' => $programs->total(),
            'current_page' => $programs->currentPage(),
            'total_pages' => $programs->lastPage(),
        ]);
    }
}

