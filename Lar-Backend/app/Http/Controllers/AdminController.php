<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\EmergencyReport;
use App\Models\AidRequest;
use App\Models\AdminNote;

class AdminController extends Controller
{
    /**
     * List all reports for admin (emergency + aid)
     */
    public function listReports()
    {
        $emergencyReports = EmergencyReport::with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        $aidRequests = AidRequest::with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'emergency_reports' => $emergencyReports,
            'aid_requests' => $aidRequests,
        ]);
    }

    /**
     * Update status of a report (emergency or aid)
     */
    public function updateStatus(Request $request)
    {
        $request->validate([
            'type' => 'required|in:emergency,aid',
            'report_id' => 'required|integer',
            'status' => 'required|in:pending,in_progress,completed',
            'admin_note' => 'nullable|string'
        ]);

        if ($request->type === 'emergency') {
            $report = EmergencyReport::find($request->report_id);
        } else {
            $report = AidRequest::find($request->report_id);
        }

        if (!$report) {
            return response()->json([
                'success' => false,
                'message' => 'Report not found',
            ], 404);
        }

        $report->status = $request->status;
        $report->save();

        // Add admin note if provided
        if ($request->filled('admin_note')) {
            AdminNote::create([
                'report_type' => $request->type,
                'report_id' => $report->id,
                'admin_id' => auth()->id(),
                'note' => $request->admin_note,
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Report status updated successfully',
            'report' => $report,
        ]);
    }
}
