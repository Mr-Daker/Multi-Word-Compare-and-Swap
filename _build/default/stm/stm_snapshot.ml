(** Snapshot implemented on top of the STM-style volatile interface. *)

type 'a t = {
  slots : 'a Stm_volatile.ref array;
  n : int;
}

let init n v =
  if n <= 0 then invalid_arg "Stm_snapshot.init: size must be positive";
  { slots = Array.init n (fun _ -> Stm_volatile.ref v); n }

let create = init

let size t = t.n

let check_index t i =
  if i < 0 || i >= t.n then invalid_arg "Stm_snapshot.update: index out of bounds"

let update t i v =
  check_index t i;
  let rec retry () =
    let current = Stm_volatile.get t.slots.(i) in
    let op = Stm_volatile.make_op t.slots.(i) ~expected:current ~desired:v in
    if not (Stm_volatile.commit [ op ]) then retry ()
  in
  retry ()

let rec scan t =
  let snapshot = Array.map Stm_volatile.get t.slots in
  let ops =
    Array.to_list
      (Array.mapi
         (fun i value -> Stm_volatile.make_op t.slots.(i) ~expected:value ~desired:value)
         snapshot)
  in
  if Stm_volatile.commit ops then snapshot else scan t
