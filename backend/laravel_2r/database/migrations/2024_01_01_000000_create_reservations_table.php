<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reservations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('room_id', 64)->index();
            $table->string('title', 255);
            $table->dateTime('start_time');
            $table->dateTime('end_time');
            $table->uuid('client_id')->nullable()->unique()->index();
            $table->string('status', 32)->default('confirmed');
            $table->timestamps();
            $table->softDeletes();

            $table->index(['room_id', 'start_time', 'end_time']);
            $table->index(['user_id', 'start_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reservations');
    }
};
