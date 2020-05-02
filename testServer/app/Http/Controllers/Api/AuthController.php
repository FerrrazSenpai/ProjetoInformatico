<?php

namespace App\Http\Controllers\Api;

use App\User;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

// ALTERAR ESTES 3 VALORES:
//define('YOUR_SERVER_URL', 'http://127.0.0.1:8000'); 

// Check "oauth_clients" table for next 2 values: 
//define('CLIENT_ID', '2'); 
//define('CLIENT_SECRET','8bulBENEI8RuPcf5Qpx4FLsYZO2Tw0ySaE4lw1VJ');

class AuthController extends Controller
{
    public function register(Request $request)
    {
         $validatedData = $request->validate([
             'name'=>'required|max:55',
             'email'=>'email|required|unique:users',
             'password'=>'required|confirmed'
         ]);
 
         $validatedData['password'] = bcrypt($request->password);
 
         $user = User::create($validatedData);
 
         $accessToken = $user->createToken('authToken')->accessToken;
 
         return response(['user'=> $user, 'access_token'=> $accessToken]);
        
    }
 
 
    public function login(Request $request)
    {
        $http = new \GuzzleHttp\Client;
        $response = $http->post(env('PASSPORT_URL').'/oauth/token', [
            'form_params' => [
                'grant_type' => 'password', 
                'client_id' => env('PASSPORT_CLIENT_ID'), 
                'client_secret' => env('PASSPORT_SECRET'), 
                'username' => $request->email, 
                'password' => $request->password, 
                'scope' => ''
            ],
            'exceptions' => false,
        ]);
        $errorCode= $response->getStatusCode(); 
        if ($errorCode=='200') {
            return json_decode((string) $response->getBody(), true); 
        } else {
            return response()->json(
                ['msg'=>'User credentials are invalid'], $errorCode);
        } 
    }
	public function logout()
    {
        \Auth::guard('api')->user()->token()->revoke();
        \Auth::guard('api')->user()->token()->delete();
        return response()->json(['msg'=>'OK'], 200);
    }

    public function verify()
    {
        $id = Auth::id();
        return response()->json("Utilizador verificado", 200);
    }
    
    public function profile()
    {    
        $user = Auth::user();    
        return $user;
    }
}
//  $loginData = $request->validate([
        //      'email' => 'email|required',
        //      'password' => 'required'
        //  ]);
        
        //  if(!auth()->attempt($loginData)) {
        //      return response(['message'=>'Invalid credentials']);
        //  }
 
        //  $accessToken = auth()->user()->createToken('authToken')->accessToken;
 
        //  return response(['user' => auth()->user(), 'access_token' => $accessToken]);