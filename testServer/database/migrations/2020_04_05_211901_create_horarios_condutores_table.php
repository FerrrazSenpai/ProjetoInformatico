<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHorariosCondutoresTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('horarios_condutores', function (Blueprint $table) {
            $table->id()->unique();
			$table->integer('id_condutor');
			$table->integer('id_linha');
			$table->string('hora_inicio');
			$table->string('hora_fim');
			$table->timestamp('data');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('horarios_condutores', function (Blueprint $table) {
            //
        });
    }
}
