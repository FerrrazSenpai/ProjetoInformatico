<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHistoricoCondutoresTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('historico_condutores', function (Blueprint $table) {
            $table->id()->unique();
			$table->integer('id_condutor');
			$table->timestamp('data');
			$table->integer('id_linha');
			$table->string('hora_fim');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('historico_condutores', function (Blueprint $table) {
            //
        });
    }
}
