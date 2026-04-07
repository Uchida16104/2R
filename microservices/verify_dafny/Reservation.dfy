module RoomReservation {

  datatype TimeSlot = TimeSlot(start: int, end: int)

  predicate ValidSlot(s: TimeSlot) {
    s.start >= 0 && s.end > s.start
  }

  predicate Overlaps(a: TimeSlot, b: TimeSlot) {
    a.start < b.end && a.end > b.start
  }

  predicate NoOverlap(a: TimeSlot, b: TimeSlot) {
    !Overlaps(a, b)
  }

  lemma OverlapSymmetric(a: TimeSlot, b: TimeSlot)
    ensures Overlaps(a, b) == Overlaps(b, a)
  {}

  lemma NonOverlapIsExclusive(a: TimeSlot, b: TimeSlot)
    requires ValidSlot(a) && ValidSlot(b)
    requires NoOverlap(a, b)
    ensures !Overlaps(a, b)
  {}

  class Room {
    var isBooked: bool
    var bookedSlot: TimeSlot

    constructor()
      ensures !isBooked
    {
      isBooked   := false;
      bookedSlot := TimeSlot(0, 1);
    }

    method Book(slot: TimeSlot) returns (success: bool)
      requires ValidSlot(slot)
      modifies this
      ensures success  ==> isBooked && bookedSlot == slot
      ensures !success ==> isBooked == old(isBooked)
    {
      if isBooked {
        success := false;
      } else {
        isBooked   := true;
        bookedSlot := slot;
        success    := true;
      }
    }

    method Cancel()
      requires isBooked
      modifies this
      ensures !isBooked
    {
      isBooked := false;
    }

    method TryRebook(newSlot: TimeSlot) returns (success: bool)
      requires ValidSlot(newSlot)
      modifies this
      ensures success ==> isBooked && bookedSlot == newSlot
    {
      if isBooked && !NoOverlap(bookedSlot, newSlot) {
        success := false;
      } else {
        isBooked   := true;
        bookedSlot := newSlot;
        success    := true;
      }
    }
  }

  class ReservationLedger {
    var bookings: seq<TimeSlot>
    var roomIds:  seq<string>

    constructor()
      ensures |bookings| == 0
      ensures |roomIds|  == 0
    {
      bookings := [];
      roomIds  := [];
    }

    predicate NoConflictFor(room: string, slot: TimeSlot)
      reads this
    {
      forall i :: 0 <= i < |bookings| ==>
        roomIds[i] != room || NoOverlap(bookings[i], slot)
    }

    method AddBooking(room: string, slot: TimeSlot) returns (ok: bool)
      requires ValidSlot(slot)
      modifies this
      ensures ok ==> NoConflictFor(room, slot) || !old(NoConflictFor(room, slot))
    {
      if !NoConflictFor(room, slot) {
        ok := false;
        return;
      }
      bookings := bookings + [slot];
      roomIds  := roomIds  + [room];
      ok := true;
    }
  }
}
