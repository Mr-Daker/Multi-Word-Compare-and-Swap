(** Atomic Snapshot implemented using Multi-Word Compare-and-Swap (MCAS).
    This module uses the expressiveness of MCAS to provide a significantly 
    simpler implementation than the traditional double-collect algorithm. *)

(** The type of a concurrent atomic snapshot object containing values of type ['a]. *)
type 'a t

(** [init n v] creates a new snapshot object with [n] independent slots, 
    each initialized to the value [v].
    Raises [Invalid_argument] if [n < 1]. *)
val init : int -> 'a -> 'a t

(** [update t i v] updates the value at slot [i] in the snapshot [t] to [v].
    This operation is atomic and linearizable.
    Raises [Invalid_argument] if [i] is strictly out of bounds (i < 0 or i >= n). *)
val update : 'a t -> int -> 'a -> unit

(** [scan t] atomically reads the current state of the entire snapshot [t].
    Returns an array containing the values of all slots at a single, 
    linearizable point in time. 
    
    In this MCAS-backed version, a valid scan can be achieved by executing an 
    MCAS operation across all [n] slots where the expected value and desired 
    value for each slot are identical. *)
val scan : 'a t -> 'a array