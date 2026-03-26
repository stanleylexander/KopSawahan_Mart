<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PointController;
use App\Http\Controllers\ProductController;

use Illuminate\Http\Request;


//AUTH CONTROLLER
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);


//PRODUCT CONTROLLER
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class,'detail']);

Route::middleware(['auth:sanctum'])->group(function () {

    Route::post('/products', [ProductController::class, 'store']);
    Route::post('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

});


//POINT CONTROLLER
Route::get('/points/{userId}', [PointController::class, 'getUserPoint']);


Route::post('/debug-auth', function (Request $request) {
    return response()->json([
        'header' => $request->header('Authorization'),
        'token' => $request->bearerToken(),
        'user' => $request->user()
    ]);
})->middleware('auth:sanctum');