<?php

namespace App\Http\Controllers;

use App\Models\AidRequest;
use Illuminate\Http\Request;

class AidRequestController extends Controller
{
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
            'supporting_notes' => $request->supporting_notes
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Aid request submitted successfully',
            'data' => $aid
        ]);
    }

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
}
