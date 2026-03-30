<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PointController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\UserController;

use Illuminate\Http\Request;


//AUTH CONTROLLER
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);


//PRODUCT CONTROLLER
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class,'detail']);

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {

    // PRODUCT
    Route::post('/products', [ProductController::class, 'store']);
    Route::post('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    //USER
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users/{id}/role', [UserController::class, 'updateRole']);

});

Route::middleware('auth:sanctum')->get('/user', [UserController::class, 'profile']);


Route::post('/debug-auth', function (Request $request) {
    return response()->json([
        'header' => $request->header('Authorization'),
        'token' => $request->bearerToken(),
        'user' => $request->user()
    ]);
})->middleware('auth:sanctum');