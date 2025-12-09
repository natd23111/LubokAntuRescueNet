<?php

namespace App\Http\Controllers;

use App\Models\BantuanProgram;
use Illuminate\Http\Request;

class BantuanController extends Controller
{
    // Get all programs (FOR RESIDENTS & ADMINS)
    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => BantuanProgram::orderBy('created_at', 'desc')->get()
        ]);
    }

    // Create new program (ADMIN ONLY)
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required',
            'description' => 'required',
            'criteria' => 'nullable|string',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date'
        ]);

        $program = BantuanProgram::create([
            'title' => $request->title,
            'description' => $request->description,
            'criteria' => $request->criteria,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'status' => 'Active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Program created successfully',
            'data' => $program
        ]);
    }

    // Update bantuan program (ADMIN ONLY)
    public function update(Request $request, $id)
    {
        $program = BantuanProgram::findOrFail($id);

        $program->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Program updated successfully',
            'data' => $program
        ]);
    }

    // Delete bantuan program (ADMIN ONLY)
    public function destroy($id)
    {
        $program = BantuanProgram::findOrFail($id);
        $program->delete();

        return response()->json([
            'success' => true,
            'message' => 'Program deleted successfully'
        ]);
    }
}
