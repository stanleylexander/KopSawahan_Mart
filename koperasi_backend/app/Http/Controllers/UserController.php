<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{

    // GET ALL USERS
    public function index()
    {
        return response()->json(User::all());
    }


    // PROFILE
    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            "id" => $user->id,
            "name" => $user->name,
            "email" => $user->email,
            "phone_number" => $user->phone_number,
            "date_of_birth" => $user->date_of_birth,
            "gender" => $user->gender,
        ]);
    }


    // UPDATE ROLE
    public function updateRole(Request $request, $id)
    {
        $request->validate([
            'role' => 'required|in:member,worker,cashier,admin'
        ]);

        $user = User::findOrFail($id);
        $user->role = $request->role;
        $user->save();

        return response()->json([
            'message' => 'Role updated successfully',
            'user' => $user
        ]);
    }
}
