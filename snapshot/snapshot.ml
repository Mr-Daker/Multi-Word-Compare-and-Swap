(** Atomic Snapshot Implementation using Double-Collect Algorithm *)

(** Type of atomic snapshot object *)
type 'a t = {
  registers : 'a Atomic.t array;  (* Array of atomic registers *)
  n : int;                         (* Number of registers *)
}

let create _n _init_value = 
  if _n <= 0 then
    raise (Invalid_argument "Snapshot size must be positive")
  else
    { 
      registers = Array.init _n (fun _ -> Atomic.make _init_value); 
      n = _n 
    }

let update _snapshot _idx _value = 
  if _idx< 0 || _snapshot.n <=_idx then
    raise (Invalid_argument "idx is out of bounds")
  else
    Atomic.set _snapshot.registers.(_idx) _value
(* Helper: collect all register values *)
let collect _snapshot = Array.map Atomic.get _snapshot.registers

(** Scan using double-collect algorithm *)
let rec scan _snapshot = 
  let c1 = collect _snapshot in
  let c2 = collect _snapshot in
  if c1 = c2 then c1 
  else scan _snapshot 

let size _snapshot = _snapshot.n


