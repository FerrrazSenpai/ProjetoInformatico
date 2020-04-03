<?php

namespace App\Http\Controllers;
use App\Location;

use Illuminate\Http\Request;

class LocationController extends Controller
{
    public function location(Request $request)
    { 
         $data = new Location;

         $data->latitude = $request->latitude;
         $data->longitude = $request->longitude;
         $data->speed = $request->speed;
         $data->time = $request->time;

         $data->save();

         return $data;
    }
}
