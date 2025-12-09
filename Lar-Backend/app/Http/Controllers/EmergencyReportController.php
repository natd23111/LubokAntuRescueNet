<?php
namespace App\Http\Controllers;

use App\Models\EmergencyReport;
use Illuminate\Http\Request;

class EmergencyReportController extends Controller
{
    // Resident submits a report
    public function store(Request $request)
    {
        $request->validate([
            'incident_type' => 'required',
            'incident_location' => 'required',
            'description' => 'nullable|string',
            'latitude' => 'nullable',
            'longitude' => 'nullable',
            'incident_photo' => 'nullable|string'
        ]);

        $report = EmergencyReport::create([
            'user_id' => auth()->id(),
            'incident_type' => $request->incident_type,
            'incident_location' => $request->incident_location,
            'description' => $request->description,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'incident_photo' => $request->incident_photo ?? null,
            'status' => 'Submitted',
            'report_type' => 'emergency',
            'submitted_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Emergency report submitted successfully',
            'data' => $report
        ]);
    }

    // Resident fetches their reports
    public function myReports()
    {
        $reports = EmergencyReport::where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $reports
        ]);
    }

    // Admin updates status/remarks
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:Submitted,In Process,Completed',
            'admin_remarks' => 'nullable|string'
        ]);

        $report = EmergencyReport::findOrFail($id);
        $report->update([
            'status' => $request->status,
            'admin_remarks' => $request->admin_remarks,
            'admin_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Report updated successfully',
            'data' => $report
        ]);
    }
}
