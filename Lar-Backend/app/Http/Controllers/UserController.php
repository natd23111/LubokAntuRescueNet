<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserController extends Controller
{
    // Get authenticated user profile
    public function show(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user(),
        ]);
    }

    // Update user profile (email, phone, and address)
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone_no' => 'required|string|max:20',
            'address' => 'nullable|string|max:255',
        ]);

        $user->update([
            'email' => $request->email,
            'phone_no' => $request->phone_no,
            'address' => $request->address,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user,
        ]);
    }

    // Change password
    public function changePassword(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        // Check if current password is correct
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 401);
        }

        // Check if new password is different from current password
        if (Hash::check($request->new_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'New password must be different from current password',
            ], 422);
        }

        // Update password
        $user->update([
            'password' => Hash::make($request->new_password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully',
        ]);
    }

    // Get user statistics
    public function getStats(Request $request)
    {
        $user = $request->user();

        // Get counts (adjust based on your actual models)
        $activeReports = 2; // Replace with actual query
        $aidRequests = 1;   // Replace with actual query
        $newPrograms = 5;   // Replace with actual query

        return response()->json([
            'success' => true,
            'stats' => [
                'active_reports' => $activeReports,
                'aid_requests' => $aidRequests,
                'new_programs' => $newPrograms,
            ],
        ]);
    }
}
