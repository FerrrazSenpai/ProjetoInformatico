<?php

namespace App\Http\Controllers;
use App\Location;

use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

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

    public function markers(Request $request)
    { 
        $a=DB::table('linha_paragem')->where('id_linha','1')->pluck('id_paragem'); //[idParagem, idParagem, idParagem ......]
        if($a->isEmpty()){
            return $a;
        }

        foreach ($a as $paragem){ 
            $a= DB::table('paragem')->where('id',$paragem)->get(); //[idParagem, idParagem, idParagem ......]   
            $lista[]=$a[0];
        }

        return $lista;
    }
}
