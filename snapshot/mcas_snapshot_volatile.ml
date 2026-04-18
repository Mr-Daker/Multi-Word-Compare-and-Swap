(** Atomic snapshot implemented using volatile MCAS. *)

type 'a t = {
  slots : 'a Mcas_volatile.ref array;
  n : int;
}

let init n v =
  if n <= 0 then invalid_arg "MCAS_Snapshot_Volatile.init: size must be positive";
  { slots = Array.init n (fun _ -> Mcas_volatile.ref v); n }

let create = init

let size t = t.n

let check_index t i =
  if i < 0 || i >= t.n then
    invalid_arg "MCAS_Snapshot_Volatile.update: index out of bounds"

let update t i v =
  check_index t i;
  let rec retry () =
    let current = Mcas_volatile.get t.slots.(i) in
    let op = Mcas_volatile.make_cas t.slots.(i) ~expected:current ~desired:v in
    if not (Mcas_volatile.mcas [ op ]) then retry ()
  in
  retry ()

let rec scan t =
  let snapshot = Array.map Mcas_volatile.get t.slots in
  let ops =
    Array.to_list
      (Array.mapi
         (fun i value ->
           Mcas_volatile.make_cas t.slots.(i) ~expected:value ~desired:value)
         snapshot)
  in
  if Mcas_volatile.mcas ops then snapshot else scan t
