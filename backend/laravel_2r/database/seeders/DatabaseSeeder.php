<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@2r.local'],
            [
                'name'     => 'Admin',
                'password' => Hash::make('password'),
            ]
        );

        User::firstOrCreate(
            ['email' => 'user@2r.local'],
            [
                'name'     => 'Demo User',
                'password' => Hash::make('password'),
            ]
        );
    }
}