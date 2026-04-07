<?php

namespace App\Http\Controllers;

use App\Models\Reservation;
use App\Services\VerificationService;
use App\Services\AvailabilityService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class ReservationController extends Controller
{
    public function __construct(
        private VerificationService $verificationService,
        private AvailabilityService $availabilityService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $query = Reservation::query()
            ->where('user_id', $request->user()->id)
            ->orderBy('start_time');

        if ($request->has('room_id')) {
            $query->where('room_id', $request->room_id);
        }

        if ($request->has('from')) {
            $query->where('start_time', '>=', $request->from);
        }

        if ($request->has('to')) {
            $query->where('start_time', '<=', $request->to);
        }

        return response()->json($query->paginate(50));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'room_id'    => 'required|string|max:64',
            'title'      => 'required|string|max:255',
            'start_time' => 'required|date|after:now',
            'end_time'   => 'required|date|after:start_time',
            'client_id'  => 'nullable|string|uuid',
        ]);

        try {
            $reservation = DB::transaction(function () use ($validated, $request) {
                $available = $this->availabilityService->isAvailable(
                    $validated['room_id'],
                    $validated['start_time'],
                    $validated['end_time']
                );

                if (!$available) {
                    throw new \RuntimeException('Room is not available for the requested time slot.');
                }

                $verified = $this->verificationService->verifyBookingInvariant(
                    $validated['room_id'],
                    $validated['start_time'],
                    $validated['end_time']
                );

                if (!$verified) {
                    throw new \RuntimeException('Booking invariant verification failed.');
                }

                return Reservation::create([
                    'user_id'    => $request->user()->id,
                    'room_id'    => $validated['room_id'],
                    'title'      => $validated['title'],
                    'start_time' => $validated['start_time'],
                    'end_time'   => $validated['end_time'],
                    'client_id'  => $validated['client_id'] ?? null,
                    'status'     => 'confirmed',
                ]);
            });

            return response()->json($reservation, 201);
        } catch (\RuntimeException $e) {
            return response()->json(['error' => $e->getMessage()], 409);
        }
    }

    public function show(int $id, Request $request): JsonResponse
    {
        $reservation = Reservation::where('user_id', $request->user()->id)->findOrFail($id);
        return response()->json($reservation);
    }

    public function update(int $id, Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'      => 'sometimes|string|max:255',
            'start_time' => 'sometimes|date|after:now',
            'end_time'   => 'sometimes|date|after:start_time',
        ]);

        $reservation = Reservation::where('user_id', $request->user()->id)->findOrFail($id);

        try {
            $updated = DB::transaction(function () use ($reservation, $validated) {
                if (isset($validated['start_time']) || isset($validated['end_time'])) {
                    $startTime = $validated['start_time'] ?? $reservation->start_time;
                    $endTime   = $validated['end_time']   ?? $reservation->end_time;

                    $available = $this->availabilityService->isAvailableExcluding(
                        $reservation->room_id,
                        $startTime,
                        $endTime,
                        $reservation->id
                    );

                    if (!$available) {
                        throw new \RuntimeException('Room is not available for the updated time slot.');
                    }
                }

                $reservation->update($validated);
                return $reservation->fresh();
            });

            return response()->json($updated);
        } catch (\RuntimeException $e) {
            return response()->json(['error' => $e->getMessage()], 409);
        }
    }

    public function destroy(int $id, Request $request): JsonResponse
    {
        $reservation = Reservation::where('user_id', $request->user()->id)->findOrFail($id);
        $reservation->update(['status' => 'cancelled']);
        $reservation->delete();
        return response()->json(null, 204);
    }

    public function sync(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'records'                => 'required|array',
            'records.*.client_id'   => 'required|string|uuid',
            'records.*.room_id'     => 'required|string|max:64',
            'records.*.title'       => 'required|string|max:255',
            'records.*.start_time'  => 'required|date',
            'records.*.end_time'    => 'required|date',
            'records.*.client_ts'   => 'required|integer',
        ]);

        $results = [];

        foreach ($validated['records'] as $record) {
            $existing = Reservation::where('client_id', $record['client_id'])->first();

            if ($existing) {
                $results[] = ['client_id' => $record['client_id'], 'status' => 'already_exists', 'id' => $existing->id];
                continue;
            }

            try {
                $available = $this->availabilityService->isAvailable(
                    $record['room_id'],
                    $record['start_time'],
                    $record['end_time']
                );

                if (!$available) {
                    $results[] = ['client_id' => $record['client_id'], 'status' => 'conflict'];
                    continue;
                }

                $reservation = Reservation::create([
                    'user_id'    => $request->user()->id,
                    'room_id'    => $record['room_id'],
                    'title'      => $record['title'],
                    'start_time' => $record['start_time'],
                    'end_time'   => $record['end_time'],
                    'client_id'  => $record['client_id'],
                    'status'     => 'confirmed',
                ]);

                $results[] = ['client_id' => $record['client_id'], 'status' => 'created', 'id' => $reservation->id];
            } catch (\Exception $e) {
                Log::error('Sync error', ['client_id' => $record['client_id'], 'error' => $e->getMessage()]);
                $results[] = ['client_id' => $record['client_id'], 'status' => 'error'];
            }
        }

        return response()->json(['results' => $results]);
    }
}
