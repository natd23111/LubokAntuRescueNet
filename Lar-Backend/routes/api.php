<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\EmergencyReportController;
use App\Http\Controllers\AidRequestController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\BantuanController;
use App\Http\Controllers\ReportsController;

// Auth routes
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Public routes (no authentication required)
Route::get('/reports', [ReportsController::class, 'index']);
Route::get('/reports/{id}', [ReportsController::class, 'show']);

// Protected routes (requires authentication)
Route::middleware(['auth:sanctum'])->group(function () {

    // User profile
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // User routes
    Route::get('/user/profile', [UserController::class, 'show']);
    Route::put('/user/profile', [UserController::class, 'updateProfile']);
    Route::post('/user/change-password', [UserController::class, 'changePassword']);
    Route::get('/user/stats', [UserController::class, 'getStats']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // User's own reports
    Route::get('/reports/my', [ReportsController::class, 'myReports']);

    // ------------------------
    // Resident Routes
    // ------------------------
    Route::post('/reports/emergency', [EmergencyReportController::class, 'store']);
    Route::get('/emergency/my', [EmergencyReportController::class, 'myReports']);

    Route::post('/reports/aid', [AidRequestController::class, 'store']);
    Route::get('/aid/my', [AidRequestController::class, 'myRequests']);

    Route::get('/bantuan', [BantuanController::class, 'index']);
    Route::get('/bantuan/{id}', [BantuanController::class, 'show']);
    Route::get('/bantuan/category/{category}', [BantuanController::class, 'getByCategory']);
    Route::get('/bantuan/categories', [BantuanController::class, 'getCategories']);
    Route::get('/bantuan/program-types', [BantuanController::class, 'getProgramTypes']);
    Route::get('/bantuan/search', [BantuanController::class, 'search']);
    Route::get('/bantuan/active', [BantuanController::class, 'getActive']);
    Route::get('/bantuan/stats', [BantuanController::class, 'getStats']);

    // ------------------------
    // Admin Routes
    // ------------------------
    Route::middleware('role:admin')->group(function () {

        // Emergency Reports
        Route::get('/admin/reports/emergency', [AdminController::class, 'listEmergencyReports']);
        Route::post('/admin/reports/emergency/update/{id}', [EmergencyReportController::class, 'updateStatus']);

        // Aid Requests
        Route::get('/admin/reports/aid', [AdminController::class, 'listAidRequests']);
        Route::post('/admin/reports/aid/update/{id}', [AidRequestController::class, 'updateStatus']);

        // Bantuan Programs - CRUD
        Route::post('/admin/bantuan', [BantuanController::class, 'store']);
        Route::put('/admin/bantuan/{id}', [BantuanController::class, 'update']);
        Route::delete('/admin/bantuan/{id}', [BantuanController::class, 'destroy']);
        Route::patch('/admin/bantuan/{id}/toggle-status', [BantuanController::class, 'toggleStatus']);

        // Reports Management (admin only)
        Route::get('/admin/reports/stats', [ReportsController::class, 'stats']);
        Route::post('/admin/reports', [ReportsController::class, 'store']);
        Route::put('/admin/reports/{id}', [ReportsController::class, 'update']);
        Route::delete('/admin/reports/{id}', [ReportsController::class, 'destroy']);
    });
});
