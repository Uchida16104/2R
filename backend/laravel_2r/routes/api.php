<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ReservationController;
use App\Http\Controllers\AnalyticsController;
use App\Http\Controllers\AvailabilityController;
use App\Http\Controllers\AuthController;

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/reservations', [ReservationController::class, 'index']);
    Route::post('/reservations', [ReservationController::class, 'store']);
    Route::get('/reservations/{id}', [ReservationController::class, 'show']);
    Route::put('/reservations/{id}', [ReservationController::class, 'update']);
    Route::delete('/reservations/{id}', [ReservationController::class, 'destroy']);
    Route::post('/reservations/sync', [ReservationController::class, 'sync']);

    Route::get('/availability', [AvailabilityController::class, 'index']);
    Route::get('/availability/{room}', [AvailabilityController::class, 'show']);

    Route::get('/analytics/usage', [AnalyticsController::class, 'usage']);
    Route::get('/analytics/forecast', [AnalyticsController::class, 'forecast']);
});

Route::get('/health', fn() => response()->json(['status' => 'ok', 'timestamp' => now()->toIso8601String()]));
