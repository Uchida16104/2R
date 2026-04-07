<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AnalyticsController extends Controller
{
    private string $analyticsUrl;

    public function __construct()
    {
        $this->analyticsUrl = config('services.analytics.url', 'http://analytics_python:8001');
    }

    public function usage(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'from' => 'required|date',
            'to'   => 'required|date|after:from',
        ]);

        try {
            $response = Http::timeout(10)
                ->get("{$this->analyticsUrl}/analytics/usage", $validated);

            if ($response->successful()) {
                return response()->json($response->json());
            }

            return response()->json(['error' => 'Analytics service unavailable'], 503);
        } catch (\Exception $e) {
            Log::error('Analytics usage error', ['error' => $e->getMessage()]);
            return response()->json(['error' => 'Analytics service unreachable'], 503);
        }
    }

    public function forecast(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'room_id' => 'required|string|max:64',
            'days'    => 'integer|min:1|max:90',
        ]);

        try {
            $response = Http::timeout(15)
                ->get("{$this->analyticsUrl}/analytics/forecast", $validated);

            if ($response->successful()) {
                return response()->json($response->json());
            }

            return response()->json(['error' => 'Forecast service unavailable'], 503);
        } catch (\Exception $e) {
            Log::error('Analytics forecast error', ['error' => $e->getMessage()]);
            return response()->json(['error' => 'Forecast service unreachable'], 503);
        }
    }
}
