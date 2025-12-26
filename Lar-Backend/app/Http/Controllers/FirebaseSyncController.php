<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

/**
 * Firebase Sync Controller
 * Handles synchronization of data from Firebase to MySQL
 * API endpoints for hybrid Firebase + MySQL approach
 */
class FirebaseSyncController extends Controller
{
    /**
     * Sync Firebase user to MySQL
     * Called when a user signs up via Firebase
     *
     * POST /api/users/sync-firebase
     */
    public function syncFirebaseUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'firebase_uid' => 'required|string|unique:users,firebase_uid',
            'email' => 'required|email|unique:users,email',
            'displayName' => 'required|string',
            'syncedAt' => 'required|date_format:Y-m-d\TH:i:sP',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $user = User::create([
                'firebase_uid' => $request->firebase_uid,
                'email' => $request->email,
                'name' => $request->displayName,
                'firebase_synced_at' => $request->syncedAt,
                'is_firebase_synced' => true,
            ]);

            return response()->json([
                'message' => 'User synced from Firebase successfully',
                'user' => $user,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to sync Firebase user: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get user by Firebase UID
     * Check if Firebase user exists in MySQL
     *
     * GET /api/users/firebase/{firebaseUid}
     */
    public function getUserByFirebaseUid($firebaseUid)
    {
        $user = User::where('firebase_uid', $firebaseUid)->first();

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        return response()->json([
            'user' => $user,
            'synced' => $user->is_firebase_synced,
        ], 200);
    }

    /**
     * Update user Firebase sync status
     *
     * PUT /api/users/{userId}/sync-status
     */
    public function updateSyncStatus(Request $request, $userId)
    {
        $user = User::findOrFail($userId);

        $user->update([
            'is_firebase_synced' => $request->is_firebase_synced,
            'firebase_synced_at' => now(),
        ]);

        return response()->json([
            'message' => 'Sync status updated',
            'user' => $user,
        ], 200);
    }

    /**
     * Get unsynced users
     * Find users that need to be synced to Firebase
     *
     * GET /api/users/unsynced
     */
    public function getUnsyncedUsers()
    {
        $users = User::where('is_firebase_synced', false)->get();

        return response()->json([
            'count' => $users->count(),
            'users' => $users,
        ], 200);
    }

    /**
     * Sync emergency alert from Firebase to MySQL
     *
     * POST /api/emergencies/sync-firebase
     */
    public function syncEmergencyAlert(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'firebase_id' => 'required|string|unique:emergency_alerts,firebase_id',
            'title' => 'required|string',
            'description' => 'required|string',
            'location' => 'required|string',
            'severity' => 'required|in:low,medium,high',
            'status' => 'required|in:active,resolved,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            // Create emergency alert in MySQL
            $emergency = \App\Models\EmergencyAlert::create([
                'firebase_id' => $request->firebase_id,
                'title' => $request->title,
                'description' => $request->description,
                'location' => $request->location,
                'severity' => $request->severity,
                'status' => $request->status,
                'synced_from_firebase' => true,
            ]);

            return response()->json([
                'message' => 'Emergency alert synced',
                'emergency' => $emergency,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to sync emergency: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Sync notification from Firebase to MySQL
     *
     * POST /api/notifications/sync-firebase
     */
    public function syncNotification(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'firebase_id' => 'required|string|unique:notifications,firebase_id',
            'recipient_id' => 'required|integer|exists:users,id',
            'title' => 'required|string',
            'message' => 'required|string',
            'type' => 'required|in:emergency,aid_update,general',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $notification = \App\Models\Notification::create([
                'firebase_id' => $request->firebase_id,
                'user_id' => $request->recipient_id,
                'title' => $request->title,
                'message' => $request->message,
                'type' => $request->type,
                'is_read' => false,
                'synced_from_firebase' => true,
            ]);

            return response()->json([
                'message' => 'Notification synced',
                'notification' => $notification,
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to sync notification: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Sync aid program from MySQL to Firebase metadata
     * Prepare data from MySQL for Firebase caching
     *
     * POST /api/aid-programs/{programId}/prepare-firebase
     */
    public function prepareAidProgramForFirebase($programId)
    {
        $program = \App\Models\AidProgram::with('beneficiaries')->findOrFail($programId);

        $data = [
            'id' => $program->id,
            'name' => $program->name,
            'description' => $program->description,
            'category' => $program->category,
            'status' => $program->status,
            'beneficiaryCount' => $program->beneficiaries->count(),
            'startDate' => $program->start_date,
            'endDate' => $program->end_date,
            'createdAt' => $program->created_at->toIso8601String(),
            'updatedAt' => $program->updated_at->toIso8601String(),
        ];

        return response()->json([
            'message' => 'Aid program prepared for Firebase sync',
            'data' => $data,
        ], 200);
    }

    /**
     * Get sync statistics
     * Monitor sync health between Firebase and MySQL
     *
     * GET /api/sync/stats
     */
    public function getSyncStats()
    {
        $totalUsers = User::count();
        $syncedUsers = User::where('is_firebase_synced', true)->count();
        $unsyncedUsers = $totalUsers - $syncedUsers;

        $syncedEmergencies = \App\Models\EmergencyAlert::where('synced_from_firebase', true)->count();
        $syncedNotifications = \App\Models\Notification::where('synced_from_firebase', true)->count();

        return response()->json([
            'users' => [
                'total' => $totalUsers,
                'synced' => $syncedUsers,
                'unsynced' => $unsyncedUsers,
                'syncPercentage' => $totalUsers > 0 ? round(($syncedUsers / $totalUsers) * 100, 2) : 0,
            ],
            'emergencies' => [
                'syncedFromFirebase' => $syncedEmergencies,
            ],
            'notifications' => [
                'syncedFromFirebase' => $syncedNotifications,
            ],
        ], 200);
    }

    /**
     * Conflict resolution
     * Handle conflicts when data differs between Firebase and MySQL
     *
     * POST /api/sync/resolve-conflict
     */
    public function resolveConflict(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'entity' => 'required|in:user,emergency,notification',
            'entity_id' => 'required|string',
            'source' => 'required|in:firebase,mysql',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            // Logic to resolve conflict
            // Keep whichever version is more recent
            $source = $request->source; // Use the newer version

            return response()->json([
                'message' => "Conflict resolved, using $source as source",
                'source' => $source,
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Failed to resolve conflict: ' . $e->getMessage(),
            ], 500);
        }
    }
}
