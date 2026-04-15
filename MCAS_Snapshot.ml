(** Atomic Snapshot implemented using Multi-Word Compare-and-Swap (MCAS).
    This module uses the expressiveness of MCAS to provide a significantly 
    simpler implementation than the traditional double-collect algorithm. *)

(** The type of a concurrent atomic snapshot object containing values of type ['a]. 
    In this implementation, we use an array of MCAS-capable references. *)
type 'a t = {
  slots : 'a Mcas.ref array; (* Array of MCAS references *)
  n : int;                   (* Number of slots *)
}

(** [init n v] creates a new snapshot object with [n] independent slots, 
    each initialized to the value [v].
    Raises [Invalid_argument] if [n < 1]. *)
let init _n _v = 
  failwith "Not implemented"

(** [update t i v] updates the value at slot [i] in the snapshot [t] to [v].
    This operation is atomic and linearizable.
    Raises [Invalid_argument] if [i] is strictly out of bounds (i < 0 or i >= n). *)
let update _t _i _v = 
  failwith "Not implemented"

(** [scan t] atomically reads the current state of the entire snapshot [t].
    Returns an array containing the values of all slots at a single, 
    linearizable point in time. *)
let scan _t = 
  failwith "Not implemented"

(* Optional: If you want to keep perfect compatibility with your Assignment 2 
   test suite (which expects a `size` function), you can add it here too: *)
let size t = t.n