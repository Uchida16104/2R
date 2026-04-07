module Reservation

open FStar.All
open FStar.Integers

type epoch = n:int{n >= 0}

noeq type time_slot = {
  start_epoch : epoch;
  end_epoch   : epoch;
}

let valid_slot (s: time_slot) : prop =
  s.end_epoch > s.start_epoch

let overlaps (a b: time_slot) : bool =
  a.start_epoch < b.end_epoch && a.end_epoch > b.start_epoch

let no_overlap (a b: time_slot) : prop =
  ~(overlaps a b == true)

val overlap_symmetric : a:time_slot -> b:time_slot ->
  Lemma (overlaps a b == overlaps b a)
let overlap_symmetric a b = ()

val valid_non_overlapping_merge :
  a:time_slot{valid_slot a} ->
  b:time_slot{valid_slot b /\ no_overlap a b} ->
  Lemma (overlaps a b == false)
let valid_non_overlapping_merge a b = ()

noeq type booking = {
  room_id    : string;
  slot       : time_slot;
  is_booked  : bool;
}

let booking_invariant (b: booking) : prop =
  b.is_booked ==> valid_slot b.slot

val make_booking :
  room_id:string ->
  s:time_slot{valid_slot s} ->
  Tot (b:booking{booking_invariant b /\ b.is_booked == true})
let make_booking room s =
  { room_id = room; slot = s; is_booked = true }

val cancel_booking :
  b:booking{b.is_booked == true} ->
  Tot (b':booking{b'.is_booked == false /\ b'.room_id == b.room_id})
let cancel_booking b =
  { b with is_booked = false }

type booking_list = list booking

let no_double_booking (bs: booking_list) (room: string) : prop =
  forall (i j: nat).
    i < List.Tot.length bs /\
    j < List.Tot.length bs /\
    i <> j ==>
    (let bi = List.Tot.index bs i in
     let bj = List.Tot.index bs j in
     bi.room_id = room /\ bj.room_id = room /\
     bi.is_booked /\ bj.is_booked ==>
     no_overlap bi.slot bj.slot)
