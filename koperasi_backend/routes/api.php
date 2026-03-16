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
Route::get('/products/{id}', [ProductController::class,'detail']);
Route::post('/products', [ProductController::class,'store']);
Route::put('/products/{id}', [ProductController::class,'update']);
Route::delete('/products/{id}', [ProductController::class,'destroy']);


//POINT CONTROLLER
Route::get('/points/{userId}', [PointController::class, 'getUserPoint']);