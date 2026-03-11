<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Point;

class PointController extends Controller
{
    public function getUserPoint($userId){
        $point = Point::where('user_id', $userId)->first();

        if(!$point){
            return response()->json([
                "point"=>0
            ]);
        }

        return response()->json([
            "point"=> $point->point
        ]);
    }
}
