<?php

namespace App\Services;

use App\Models\Reservation;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class AvailabilityService
    private string $rustServiceUrl;

    public function __construct()
    {
        $this->rustServiceUrl = config('services.auth_rust.url', 'http://auth_rust:3001');
    }

    public function isAvailable(string $roomId, string $startTime, string $endTime): bool
    {
        $conflict = Reservation::active()
            ->forRoom($roomId)
            ->overlapping($startTime, $endTime)
            ->exists();

        return !$conflict;
    }

    public function isAvailableExcluding(string $roomId, string $startTime, string $endTime, int $excludeId): bool
    {
        $conflict = Reservation::active()
            ->forRoom($roomId)
            ->overlapping($startTime, $endTime)
            ->where('id', '!=', $excludeId)
            ->exists();

        return !$conflict;
    }

    public function getAllRoomAvailability(string $date): array
    {
        $cacheKey = "availability_all_{$date}";

        return Cache::remember($cacheKey, 60, function () use ($date) {
            try {
                $response = Http::timeout(5)
                    ->get("{$this->rustServiceUrl}/availability", ['date' => $date]);

                if ($response->successful()) {
                    return $response->json();
                }
            } catch (\Exception $e) {
                Log::warning('Rust availability service unavailable, falling back to PHP', [
                    'error' => $e->getMessage(),
                ]);
            }

            return $this->computeAvailabilityFallback($date);
        });
    }

    public function getRoomAvailability(string $roomId, string $date): array
    {
        $cacheKey = "availability_{$roomId}_{$date}";

        return Cache::remember($cacheKey, 60, function () use ($roomId, $date) {
            $startOfDay = "{$date} 00:00:00";
            $endOfDay   = "{$date} 23:59:59";

            $booked = Reservation::active()
                ->forRoom($roomId)
                ->whereBetween('start_time', [$startOfDay, $endOfDay])
                ->get(['start_time', 'end_time'])
                ->map(fn($r) => [
                    'start' => $r->start_time->toIso8601String(),
                    'end'   => $r->end_time->toIso8601String(),
                    'available' => false,
                ]);

            return [
                'room_id' => $roomId,
                'date'    => $date,
                'slots'   => $booked->values(),
            ];
        });
    }

    {
        $rooms = Reservation::active()
            ->whereDate('start_time', $date)
            ->pluck('room_id')
            ->unique()
            ->values();

        return $rooms->map(fn($room) => $this->getRoomAvailability($room, $date))->all();
    }
}
