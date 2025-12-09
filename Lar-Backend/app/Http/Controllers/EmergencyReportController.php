<?php

namespace App\Http\Controllers;

use App\Models\EmergencyReport;
use Illuminate\Http\Request;

class EmergencyReportController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'incident_type' => 'required',
            'incident_location' => 'required',
            'description' => 'nullable|string',
            'latitude' => 'nullable',
            'longitude' => 'nullable'
        ]);

        $report = EmergencyReport::create([
            'user_id' => auth()->id(),
            'incident_type' => $request->incident_type,
            'incident_location' => $request->incident_location,
            'description' => $request->description,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'incident_photo' => $request->incident_photo ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Emergency report submitted successfully',
            'data' => $report
        ]);
    }

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
}
