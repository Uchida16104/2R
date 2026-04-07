<?php

namespace App\Providers;

use App\Services\AvailabilityService;
use App\Services\VerificationService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(AvailabilityService::class, fn() => new AvailabilityService());
        $this->app->singleton(VerificationService::class, fn() => new VerificationService());
    }

    public function boot(): void {}
}