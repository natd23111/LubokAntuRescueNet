<?php

namespace App\Http\Controllers;

use App\Models\AidRequest;
use Illuminate\Http\Request;

class AidRequestController extends Controller
{
    // Resident submits aid request
    public function store(Request $request)
    {
        $request->validate([
            'aid_type' => 'required',
            'household_size' => 'required|integer',
            'income_level' => 'nullable|string',
            'supporting_notes' => 'nullable|string'
        ]);

        $aid = AidRequest::create([
            'user_id' => auth()->id(),
            'aid_type' => $request->aid_type,
            'household_size' => $request->household_size,
            'income_level' => $request->income_level,
            'supporting_notes' => $request->supporting_notes,
            'status' => 'Submitted',
            'report_type' => 'aid',
            'submitted_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Aid request submitted successfully',
            'data' => $aid
        ]);
    }

    // Resident fetches their aid requests
    public function myRequests()
    {
        $aid = AidRequest::where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $aid
        ]);
    }

    // Admin updates status/remarks
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:Submitted,In Process,Completed,Rejected',
            'admin_remarks' => 'nullable|string'
        ]);

        $aid = AidRequest::findOrFail($id);
        $aid->update([
            'status' => $request->status,
            'admin_remarks' => $request->admin_remarks,
            'admin_id' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Aid request updated successfully',
            'data' => $aid
        ]);
    }
}
