<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PointController;
use App\Http\Controllers\ProductController;


//AUTH CONTROLLER
Route::post('/register', [AuthController::class, 'register']);

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);
});


//PRODUCT CONTROLLER
Route::get('/products', [ProductController::class, 'index']);


//POINT CONTROLLER
Route::get('/points/{userId}', [PointController::class, 'getUserPoint']);