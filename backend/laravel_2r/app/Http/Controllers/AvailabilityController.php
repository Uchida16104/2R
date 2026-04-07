<?php

namespace App\Http\Controllers;

use App\Services\AvailabilityService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class AvailabilityController extends Controller
{
    public function __construct(private AvailabilityService $availabilityService) {}

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
        ]);

        $slots = $this->availabilityService->getAllRoomAvailability($validated['date']);
        return response()->json($slots);
    }

    public function show(string $room, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => 'required|date',
        ]);

        $slots = $this->availabilityService->getRoomAvailability($room, $validated['date']);
        return response()->json($slots);
    }
}
