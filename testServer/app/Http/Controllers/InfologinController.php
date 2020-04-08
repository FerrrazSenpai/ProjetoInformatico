<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;


class InfologinController extends Controller
{
    public function info(Request $request)
    {         
        $a= DB::table('autocarros')->where('estado','livre')->pluck('id');
        $b= DB::table('users')->where('email', $request->email)->pluck('id');

        $day = date("Y-m-d",strtotime($request->data));
        $time = date("H:i:s",strtotime($request->data));
        
        $c=DB::table('horarios_condutores')->where('id_condutor', $b)->whereDate('data', $day)->whereTime('hora_inicio', '<=', $time)->whereTime('hora_fim', '>', $time)->pluck('id_linha');
       
		$d=DB::table('linhas')->pluck('linha');

        return response()->json([
			'autocarros_livres'=>$a,
            'id_condutor'=>$b,
			'linhas'=>$d,
            'id_linha'=>$c
		]);

    }

    public function updateinfo(Request $request)
    {
        DB::table('autocarros')->where('id',$request->id_autocarro)->update(array('estado'=>'livre'));
        //$autocarro = Task::findOrFail($request->id);
        

        DB::table('historico_condutores')->insert(
            ['id_condutor' => $request->id_condutor, 'data' => $request->time, 'id_linha' => $request->id_linha]
        );

        return response()->json(['success' => 'success'], 200);
    }
}
