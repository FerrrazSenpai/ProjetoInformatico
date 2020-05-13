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
       /*
        $a=DB::table('linha_paragem')->select('id_paragem', 'id_linha')->get(); //[idParagem, idParagem, idParagem ......]
        if($a->isEmpty()){
            return $a;
        }
        //return $a[0];/////////////////
       
        foreach ($a as $paragem){ 
            $a1= DB::table('paragem')->where('id',$paragem->id_paragem)->get(); //[idParagem, idParagem, idParagem ......]   
          
            $a1[0]->id_linha = $paragem->id_linha;

            $lista[]=$a1[0];
        }

        return $lista; */

        $a=DB::table('paragem')->get(); //[idParagem, idParagem, idParagem ......]
        //return $a;
        foreach ($a as $paragem){ 


            $a1['linhas']= DB::table('linha_paragem')->where('id_paragem',$paragem->id)->get('id_linha'); //[idParagem, idParagem, idParagem ......]   

            $a1["latitude"] = $paragem->latitude;
            $a1["longitude"] = $paragem->longitude;
            $a1["id_paragem"] = $paragem->id;
            $a1["nome"] = $paragem->nome;

            
            $lista[]= $a1;

        }

        return $lista;

    }
}
