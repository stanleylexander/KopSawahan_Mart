<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\VoucherController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\UserController;

use Illuminate\Http\Request;


// AUTH CONTROLLER
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);


// PRODUCT CONTROLLER
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class,'detail']);


// MEMBER 
Route::middleware('auth:sanctum')->group(function () {

    //PROFILE
    Route::get('/user', [UserController::class, 'profile']);

    // VOUCHER
    Route::get('/vouchers', [VoucherController::class, 'index']);
    Route::post('/vouchers/{id}/redeem', [VoucherController::class, 'redeem']);
    Route::get('/my-vouchers', [VoucherController::class, 'myVouchers']);
});


// ADMIN
Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {

    // PRODUCT
    Route::post('/products', [ProductController::class, 'store']);
    Route::post('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);

    //USER
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users/{id}/role', [UserController::class, 'updateRole']);

    // VOUCHER
    Route::post('/vouchers', [VoucherController::class, 'store']);
    Route::post('/vouchers/{id}', [VoucherController::class, 'update']); 
    Route::delete('/vouchers/{id}', [VoucherController::class, 'destroy']); 

});


Route::post('/debug-auth', function (Request $request) {
    return response()->json([
        'header' => $request->header('Authorization'),
        'token' => $request->bearerToken(),
        'user' => $request->user()
    ]);
})->middleware('auth:sanctum');