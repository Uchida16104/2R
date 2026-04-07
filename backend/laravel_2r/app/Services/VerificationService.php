<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class VerificationService
{
    private string $dafnyServiceUrl;

    public function __construct()
    {
        $this->dafnyServiceUrl = config('services.verify_dafny.url', 'http://localhost:3002');
    }

    public function verifyBookingInvariant(string $roomId, string $startTime, string $endTime): bool
    {
        try {
            $response = Http::timeout(3)->post("{$this->dafnyServiceUrl}/verify/booking", [
                'room_id'    => $roomId,
                'start_time' => $startTime,
                'end_time'   => $endTime,
            ]);

            if ($response->successful()) {
                return (bool) ($response->json()['valid'] ?? false);
            }

            Log::warning('Dafny verification service returned non-200', [
                'status' => $response->status(),
            ]);

            return true;
        } catch (\Exception $e) {
            Log::warning('Dafny verification service unreachable, allowing booking', [
                'error' => $e->getMessage(),
            ]);

            return true;
        }
    }
}
