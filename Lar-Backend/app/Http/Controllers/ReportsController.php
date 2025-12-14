<?php

namespace App\Http\Controllers;

use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ReportsController extends Controller
{
    /**
     * Display a listing of reports.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Report::query();

            // Filter by status
            if ($request->has('status')) {
                $query->where('status', $request->input('status'));
            }

            // Filter by priority
            if ($request->has('priority')) {
                $query->where('priority', $request->input('priority'));
            }

            // Filter by type
            if ($request->has('type')) {
                $query->where('type', $request->input('type'));
            }

            // Search
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('location', 'like', "%{$search}%")
                      ->orWhere('type', 'like', "%{$search}%")
                      ->orWhere('reporter_name', 'like', "%{$search}%");
                });
            }

            // Sorting
            $sortBy = $request->input('sort_by', 'date_reported');
            $sortOrder = $request->input('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            // Pagination
            $perPage = $request->input('per_page', 15);
            $reports = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $reports->items(),
                'pagination' => [
                    'total' => $reports->total(),
                    'per_page' => $reports->perPage(),
                    'current_page' => $reports->currentPage(),
                    'last_page' => $reports->lastPage(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching reports: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display reports for the authenticated user.
     */
    public function myReports(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User not authenticated',
                ], 401);
            }

            $query = Report::where('user_id', $user->id);

            // Filter by status
            if ($request->has('status')) {
                $query->where('status', $request->input('status'));
            }

            // Filter by priority
            if ($request->has('priority')) {
                $query->where('priority', $request->input('priority'));
            }

            // Filter by type
            if ($request->has('type')) {
                $query->where('type', $request->input('type'));
            }

            // Search
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('location', 'like', "%{$search}%")
                      ->orWhere('type', 'like', "%{$search}%");
                });
            }

            // Sorting
            $sortBy = $request->input('sort_by', 'date_reported');
            $sortOrder = $request->input('sort_order', 'desc');
            $query->orderBy($sortBy, $sortOrder);

            // Pagination
            $perPage = $request->input('per_page', 15);
            $reports = $query->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $reports->items(),
                'pagination' => [
                    'total' => $reports->total(),
                    'per_page' => $reports->perPage(),
                    'current_page' => $reports->currentPage(),
                    'last_page' => $reports->lastPage(),
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching user reports: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display the specified report.
     */
    public function show($id): JsonResponse
    {
        try {
            $report = Report::findOrFail($id);
            return response()->json([
                'success' => true,
                'data' => $report,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found',
            ], 404);
        }
    }

    /**
     * Store a newly created report.
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'title' => 'nullable|string',
                'type' => 'required|string',
                'location' => 'required|string',
                'description' => 'required|string',
                'priority' => 'required|in:low,medium,high',
                'reporter_name' => 'required|string',
                'reporter_ic' => 'required|string',
                'reporter_contact' => 'required|string',
                'date_reported' => 'required|date_format:Y-m-d H:i:s',
                'admin_notes' => 'nullable|string',
                'image_url' => 'nullable|url',
            ]);

            $report = Report::create([
                ...$validated,
                'status' => 'unresolved',
                'date_updated' => now(),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Report created successfully',
                'data' => $report,
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error creating report: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Update the specified report.
     */
    public function update(Request $request, $id): JsonResponse
    {
        try {
            $report = Report::findOrFail($id);

            $validated = $request->validate([
                'status' => 'sometimes|in:unresolved,in-progress,resolved',
                'priority' => 'sometimes|in:low,medium,high',
                'admin_notes' => 'nullable|string',
            ]);

            $validated['date_updated'] = now();
            $report->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Report updated successfully',
                'data' => $report,
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error updating report: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Delete the specified report.
     */
    public function destroy($id): JsonResponse
    {
        try {
            $report = Report::findOrFail($id);
            $report->delete();

            return response()->json([
                'success' => true,
                'message' => 'Report deleted successfully',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error deleting report: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get report statistics.
     */
    public function stats(): JsonResponse
    {
        try {
            $stats = [
                'total' => Report::count(),
                'unresolved' => Report::where('status', 'unresolved')->count(),
                'in_progress' => Report::where('status', 'in-progress')->count(),
                'resolved' => Report::where('status', 'resolved')->count(),
                'high_priority' => Report::where('priority', 'high')->count(),
                'by_type' => Report::selectRaw('type, COUNT(*) as count')
                    ->groupBy('type')
                    ->pluck('count', 'type'),
            ];

            return response()->json([
                'success' => true,
                'data' => $stats,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching stats: ' . $e->getMessage(),
            ], 500);
        }
    }
}
