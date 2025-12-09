<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\EmergencyReportController;
use App\Http\Controllers\AidRequestController;
use App\Http\Controllers\AdminController;

Route::middleware(['auth:sanctum'])->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {

    // Resident
    Route::post('/reports/emergency', [EmergencyReportController::class, 'store']);
    Route::post('/reports/aid', [AidRequestController::class, 'store']);
    Route::get('/reports/my', [EmergencyReportController::class, 'myReports']);

    // Admin
    Route::get('/admin/reports', [AdminController::class, 'listReports']);
    Route::post('/admin/reports/update', [AdminController::class, 'updateStatus']);
});
